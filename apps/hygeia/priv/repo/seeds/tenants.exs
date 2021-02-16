import Hygeia.TenantContext

alias Hygeia.Repo

{:ok, tenant_root} =
  create_tenant(%{
    name: "Hygeia - Covid19 Tracing",
    iam_domain: "covid19-tracing.ch"
  })

internal_public_key = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqLJ2dI4NC6fSk+rDHH6B
3Yda4LaVMFRRqLFXqGu2WwyGMK3bQrbK5dahguHE+tQP+ER1PRoemfX6udBPX2yy
C4lxT79yFVwC8pFJAfg2EwyIJAIQY4EfxjXFhqrefdofHV3WT1wNAQVtQSb0uboB
X89HcEK0GegW9cC7g1auG6taAN/Xp6CluZ1qnaPsPiYpRJpk3iyTvGSpOjVumr3A
C/AfeoQxYi82s1NbhJuEI9w71vQF0eS/cFnOtcTszc0/gc8v7Pdo3LfbROq1hCtt
yz5QUsfOxhiiVdmtD9rlrB2XlOme2IQNysVtH1hwTxtExTYseT7Gy0hk2HozvLET
3QIDAQAB
-----END PUBLIC KEY-----
"""

{:ok, tenants} =
  "CH"
  |> Cadastre.Country.new()
  |> Cadastre.Subdivision.all()
  |> Enum.map(fn
    %Cadastre.Subdivision{id: "SG"} = subdivision ->
      {subdivision,
       %{
         from_email: "Info.ContactTracing@sg.ch",
         outgoing_mail_configuration: %{
           __type__: "smtp",
           enable_relay: false
         },
         outgoing_sms_configuration: %{
           __type__: "websms",
           access_token: "***REMOVED***"
         },
         iam_domain: "kfssg.ch",
         template_variation: :sg,
         enable_sedex_export: true,
         sedex_export_configuration: %{
           recipient_id: "***REMOVED***",
           recipient_public_key: internal_public_key,
           schedule: "0 * * * *"
         },
         template_parameters: %{
           message_sender:
             "Contact Tracing St.Gallen, Appenzell Innerrhoden, Appenzell Ausserrhoden Kantonaler Führungsstab: KFS"
         }
       }}

    %Cadastre.Subdivision{id: "AR"} = subdivision ->
      {subdivision,
       %{
         from_email: "Info.ContactTracing@sg.ch",
         outgoing_mail_configuration: %{
           __type__: "smtp",
           enable_relay: false
         },
         outgoing_sms_configuration: %{
           __type__: "websms",
           access_token: "***REMOVED***"
         },
         iam_domain: "ar.covid19-tracing.ch",
         template_variation: :ar,
         enable_sedex_export: true,
         sedex_export_configuration: %{
           recipient_id: "***REMOVED***",
           recipient_public_key: internal_public_key,
           schedule: "0 * * * *"
         },
         template_parameters: %{
           message_sender:
             "Contact Tracing St.Gallen, Appenzell Innerrhoden, Appenzell Ausserrhoden Kantonaler Führungsstab: KFS"
         }
       }}

    %Cadastre.Subdivision{id: "AI"} = subdivision ->
      {subdivision,
       %{
         from_email: "Info.ContactTracing@sg.ch",
         outgoing_mail_configuration: %{
           __type__: "smtp",
           enable_relay: false
         },
         outgoing_sms_configuration: %{
           __type__: "websms",
           access_token: "***REMOVED***"
         },
         iam_domain: "ai.covid19-tracing.ch",
         template_variation: :ai,
         enable_sedex_export: true,
         sedex_export_configuration: %{
           recipient_id: "***REMOVED***",
           recipient_public_key: internal_public_key,
           schedule: "0 * * * *"
         }
       }}

    subdivision ->
      {subdivision, %{}}
  end)
  |> Enum.map(fn {%Cadastre.Subdivision{id: id, name: name}, extra_args} ->
    change_new_tenant(
      Map.merge(
        %{
          name: "Kanton #{name}",
          short_name: id,
          case_management_enabled: true
        },
        extra_args
      )
    )
  end)
  |> Enum.reduce(Ecto.Multi.new(), &PaperTrail.Multi.insert(&2, make_ref(), &1))
  |> Repo.transaction()

[tenant_root | tenants |> Map.values() |> Enum.filter(&is_struct(&1, Hygeia.TenantContext.Tenant))]
