defmodule HygeiaIam do
  @moduledoc """
  IAM
  """

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
end
