defmodule HygeiaIam do
  @moduledoc """
  IAM
  """

  defmodule OidcError do
    defexception [:message]
  end

  @spec organisation_id :: String.t()
  def organisation_id, do: Application.fetch_env!(:hygeia_iam, :organisation_id)

  @spec project_id :: String.t()
  def project_id, do: Application.fetch_env!(:hygeia_iam, :project_id)

  @spec service_login(service_user_name :: atom) ::
          {:ok, String.t(), pos_integer()} | {:error, term}
  def service_login(service_user_name) do
    with {:ok, config} <- Application.fetch_env(:hygeia_iam, :service_accounts),
         {:ok, config} <- Keyword.fetch(config, service_user_name),
         config = Map.new(config),
         {:ok, %{token_endpoint: token_endpoint} = oidc_config} <-
           :oidcc.get_openid_provider_info("zitadel"),
         {:ok, assertion} <- client_credential_jwt(config, oidc_config),
         {:ok, %{body: body}} <-
           :oidcc_http_util.sync_http(
             :post,
             token_endpoint,
             [],
             "application/x-www-form-urlencoded",
             "assertion=#{:http_uri.encode(assertion)}&grant_type=#{
               :http_uri.encode("urn:ietf:params:oauth:grant-type:jwt-bearer")
             }&scope=#{:http_uri.encode("urn:zitadel:iam:org:project:id:69234237810729019:aud")}"
           ),
         {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} <-
           Jason.decode(body) do
      {:ok, access_token, expires_in}
    else
      {:error, reason} -> {:error, reason}
      :error -> {:error, :missing_config}
      %{} -> {:error, :missing_config}
      {:ok, %{}} -> {:error, :missing_config}
    end
  end

  defp client_credential_jwt(%{login: login} = config, oidc_config) do
    with {:ok, %{"key" => key, "keyId" => key_id} = login} <- Jason.decode(login),
         jwk = JOSE.JWK.from_pem(key),
         {:ok, claims} <- client_credential_claims(config, login, oidc_config),
         header = %{
           "alg" => "RS256",
           "typ" => "JWT"
         },
         {_, assertion} <-
           jwk
           |> JOSE.JWS.sign(claims, header, %{"alg" => "RS256", "kid" => key_id})
           |> JOSE.JWS.compact() do
      {:ok, assertion}
    else
      {:error, reason} -> {:error, reason}
      {:ok, %{}} -> {:error, :missing_config}
      %{} -> {:error, :missing_config}
    end
  end

  defp client_credential_jwt(_config, _oidc_config), do: {:error, :missing_config}

  defp client_credential_claims(
         %{audience: audience} = _config,
         %{"userId" => user_id} = _login,
         %{local_endpoint: local_endpoint, issuer: issuer} = _oidc_config
       ) do
    iss =
      local_endpoint
      |> URI.parse()
      |> Map.put(:path, nil)
      |> Map.put(:query, nil)
      |> URI.to_string()

    iat = :os.system_time(:seconds)
    exp = iat + 60

    Jason.encode(%{
      "iss" => iss,
      "sub" => user_id,
      "aud" => [issuer | audience],
      "exp" => exp,
      "iat" => iat,
      "nbf" => iat
    })
  end

  defp client_credential_claims(_config, _login, _oidc_config), do: {:error, :missing_config}

  @opaque session(state) :: %{
            id: String.t(),
            provider: String.t(),
            scopes: [String.t()],
            pkce: %{
              verifier: String.t(),
              challenge: String.t(),
              method: :plain | :S256
            },
            state: state,
            expiry: NaiveDateTime.t(),
            nonce: String.t()
          }

  @spec generate_session_info(provider :: String.t(), state :: state) :: session(state)
        when state: term
  def generate_session_info(provider \\ "zitadel", state \\ nil) do
    {:ok, %{request_scopes: request_scopes} = config} = :oidcc.get_openid_provider_info("zitadel")

    %{
      id: random_string(),
      provider: provider,
      scopes:
        case request_scopes do
          :undefined -> Application.get_env(:oidcc, :scopes, [:openid])
          list when is_list(list) -> list
        end,
      pkce:
        case config do
          %{code_challenge_methods_supported: methods} -> generate_pkce(methods)
          %{} -> :undefined
        end,
      state: state,
      expiry: NaiveDateTime.add(NaiveDateTime.utc_now(), :timer.minutes(5), :millisecond),
      nonce: random_string(64)
    }
  end

  @spec generate_redirect_url!(session :: session(term())) :: String.t()
  def generate_redirect_url!(%{
        provider: provider,
        scopes: scopes,
        id: id,
        nonce: nonce,
        pkce: pkce
      }) do
    provider
    |> :oidcc.create_redirect_url(%{scopes: scopes, state: id, nonce: nonce, pkce: pkce})
    |> case do
      {:ok, url} -> url
      {:error, :provider_not_ready} -> raise OidcError, "provider not ready"
    end
  end

  @spec clean_sessions(sessions :: [session(state)]) :: [session(state)] when state: term
  def clean_sessions(sessions) do
    sessions
    |> Enum.filter(&(NaiveDateTime.compare(&1.expiry, NaiveDateTime.utc_now()) == :gt))
    |> Enum.take(2)
  end

  @spec retrieve_and_validate_token!(sessions :: [session(state)], params :: map) ::
          %{
            id: map(),
            access: map(),
            provider: String.t(),
            state: state,
            remaining_sessions: [session(state)]
          }
        when state: term

  def retrieve_and_validate_token!(sessions, params) do
    {state, code} = gather_callback_params!(params)

    %{provider: provider, pkce: pkce, nonce: nonce, scopes: scopes, state: state} =
      session = find_session(sessions, state)

    remaining_sessions = Enum.reject(sessions, &(&1 == session))

    tokens =
      code
      |> :oidcc.retrieve_and_validate_token(provider, %{nonce: nonce, pkce: pkce, scope: scopes})
      |> case do
        {:ok, tokens} ->
          tokens

        {:error, reason} when is_atom(reason) or is_binary(reason) ->
          raise OidcError, "oidc_error: #{inspect(reason)}"

        {:error, reason} ->
          raise OidcError, "oidc_error: #{inspect(reason, pretty: true)}"
      end

    Map.merge(tokens, %{
      state: state,
      remaining_sessions: remaining_sessions,
      provider: provider
    })
  end

  defp gather_callback_params!(%{"error" => error}) do
    raise OidcError, "oidc_provider_error: #{inspect(error)}"
  end

  defp gather_callback_params!(params) do
    state =
      case params["state"] do
        nil -> raise OidcError, "Query string does not contain field 'state'"
        other -> other
      end

    code =
      case params["code"] do
        nil -> raise OidcError, "Query string does not contain field 'code'"
        other -> other
      end

    {state, code}
  end

  defp find_session(sessions, state) do
    session =
      %{expiry: expiry} =
      sessions
      |> Enum.find(&(&1.id == state))
      |> case do
        nil -> raise OidcError, "session not found"
        %{} = session -> session
      end

    case NaiveDateTime.compare(expiry, NaiveDateTime.utc_now()) do
      :gt -> :ok
      :eq -> :ok
      :lt -> raise OidcError, "session expired"
    end

    session
  end

  defp generate_pkce(methods) do
    pkce_key = random_string()

    if Enum.member?(methods, "S256") do
      %{
        verifier: pkce_key,
        challenge: :sha256 |> :crypto.hash(pkce_key) |> Base.encode64(),
        method: :S256
      }
    else
      %{
        verifier: pkce_key,
        challenge: pkce_key,
        method: :plain
      }
    end
  end

  defp random_string(length \\ 32),
    do: length |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
end
