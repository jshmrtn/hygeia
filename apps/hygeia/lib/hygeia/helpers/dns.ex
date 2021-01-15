defmodule Hygeia.Helpers.DNS do
  @moduledoc false

  import Ecto.Changeset
  import HygeiaGettext

  alias Ecto.Changeset

  @spec validate_hostname(changeset :: Changeset.t(), field :: atom) :: Changeset.t()
  def validate_hostname(changeset, field) do
    validate_change(changeset, field, fn
      ^field, nil ->
        []

      ^field, hostname ->
        hostname = String.to_charlist(hostname)

        cond do
          match?({:ok, _address}, :inet.parse_address(hostname)) -> []
          match?({:ok, _address}, :inet.getaddr(hostname, :inet)) -> []
          match?({:ok, _address}, :inet.getaddr(hostname, :inet6)) -> []
          match?({:ok, _address}, :inet.getaddr(hostname, :local)) -> []
          true -> [{field, dgettext("errors", "is not a valid hostname")}]
        end
    end)
  end

  @spec validate_dkim_certificate(changeset :: Changeset.t(), field :: atom) :: Changeset.t()
  def validate_dkim_certificate(changeset, field),
    do: validate_inclusion(changeset, field, valid_cert_names())

  @spec valid_cert_names :: [String.t()]
  def valid_cert_names do
    paths = Path.wildcard(certificate_base_dir() <> "/*.pem")
    Enum.map(paths, &Path.basename(&1, ".pem"))
  end

  @spec dkim_certificate_path(private_key :: String.t()) :: Path.t()
  def dkim_certificate_path(private_key),
    do: Path.join(certificate_base_dir(), private_key <> ".pem")

  defp certificate_base_dir,
    do:
      Application.get_env(
        :hygeia,
        :dkim_certificate_directory,
        Application.app_dir(:hygeia, "priv/test/dkim/")
      )
end
