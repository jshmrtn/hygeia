# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.UpdateTenantTemplateParameters do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute("""
    UPDATE tenants
    SET template_parameters = template_parameters - 'message_sender' || JSONB_BUILD_OBJECT('sms_signature', template_parameters ->'message_sender')
    WHERE template_parameters ? 'message_sender'
    """)

    execute("""
    UPDATE tenants
    SET template_parameters = template_parameters || JSONB_BUILD_OBJECT('email_signature', 'Contact Tracing St. Gallen


    T +41 71 521 26 10
    Telefonische Erreichbarkeit:
    Mo-Fr von 08.00 - 12.00 und 14.00 - 17.00
    In dringenden Fällen ausserhalb der Telefonzeiten sowie am Wochenende kontaktieren Sie uns bitte per Mail

     info.contacttracing@sg.ch

    Kanton St. Gallen
    Gesundheitsdepartement
    Oberer Graben 32
    9001 St.Gallen
    https://www.sg.ch/tools/informationen-coronavirus.html
    ')
    WHERE name = 'Kanton Sankt Gallen'
    """)

    execute("""
    UPDATE tenants
    SET template_parameters = template_parameters || JSONB_BUILD_OBJECT('email_signature', 'Contact Tracing Appenzell Ausserrhoden


    T +41 71 521 26 10
    Telefonische Erreichbarkeit:
    Mo-Fr von 08.00 - 12.00 und 14.00 - 17.00
    In dringenden Fällen ausserhalb der Telefonzeiten sowie am Wochenende kontaktieren Sie uns bitte per Mail

     info.contacttracing@sg.ch
    Appenzell Ausserrhoden
    Departement Gesundheit und Soziales
    Amt für Gesundheit
    Kasernenstrasse 17
    9102 Herisau
    www.ar.ch')
    WHERE name = 'Kanton Appenzell Ausserrhoden'
    """)

    execute("""
    UPDATE tenants
    SET template_parameters = template_parameters || JSONB_BUILD_OBJECT('email_signature', 'Contact Tracing Appenzell Innerrhoden


    T +41 71 521 26 10
    Telefonische Erreichbarkeit:
    Mo-Fr von 08.00 - 12.00 und 14.00 - 17.00
    In dringenden Fällen ausserhalb der Telefonzeiten sowie am Wochenende kontaktieren Sie uns bitte per Mail

     info.contacttracing@sg.ch

    Kanton Appenzell Innerrhoden
    Gesundheits- und Sozialdepartement
    Kantonsarztamt
    Hoferbad 2
    9050 Appenzell

    https://www.ai.ch/coronavirus')
    WHERE name = 'Kanton Appenzell Innerrhoden'
    """)
  end
end
