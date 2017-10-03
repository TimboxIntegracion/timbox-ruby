require 'base64'
require 'savon'

# Parametros para la conexión al Webservice
wsdl_url = "https://staging.ws.timbox.com.mx/timbrado_cfdi33/wsdl"
usuario = "AAA010101000"
contrasena = "h6584D56fVdBbSmmnB"

# Parametros para la cancelación del CFDI
rfc = "AAA010101AAA"
uuid = "7520E61B-8D9A-476E-8EE5-2E3351A991A6"
pfx_path = 'archivoPfx.pfx'
bin_file = File.binread(pfx_path)
pfx_base64 = Base64.strict_encode64(bin_file)
pfx_password = "12345678a"

# Generar el Envelope para el metodo cancelar
envelope = %Q^
<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
   <soapenv:Header/>
   <soapenv:Body>
    <urn:cancelar_cfdi soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
       <username xsi:type=\"xsd:string\">#{usuario}</username>
       <password xsi:type=\"xsd:string\">#{contrasena}</password>
       <rfcemisor xsi:type=\"xsd:string\">#{rfc}</rfcemisor>
       <uuids xsi:type=\"urn:uuids\">
          <uuid xsi:type=\"xsd:string\">#{uuid}</uuid>
       </uuids>
       <pfxbase64 xsi:type=\"xsd:string\">#{pfx_base64}</pfxbase64>
       <pfxpassword xsi:type=\"xsd:string\">#{pfx_password}</pfxpassword>
    </urn:cancelar_cfdi>
 </soapenv:Body>
</soapenv:Envelope>^

# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo cancelar_cfdi
response = client.call(:cancelar_cfdi, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter el acuse de cancelación
acuse = documento.xpath("//acuse_cancelacion").text
puts acuse

# Obtener los estatus de los comprobantes cancelados
uuids_cancelados = documento.xpath("//comprobantes_cancelados").text
puts uuids_cancelados
