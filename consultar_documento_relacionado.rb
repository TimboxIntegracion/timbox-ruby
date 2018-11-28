require 'savon'
require 'nokogiri'

# Parametros para la conexión al Webservice
wsdl_url = "https://staging.ws.timbox.com.mx/cancelacion/wsdl"
usuario = "AAA010101000"
contrasena = "h6584D56fVdBbSmmnB"

# Parametros para la cancelación de documentos relacionados
rfc_receptor = "AAA010101AAA"
uuid = "8D4B79A4-B17A-4B4B-9220-9225F73B8945"

file_cer_pem = File.read('CSD01_AAA010101AAA.cer.pem')
file_key_pem = File.read('CSD01_AAA010101AAA.key.pem')

envelope = %Q^<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:WashOut">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:consultar_documento_relacionado soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
         <username xsi:type=\"xsd:string\">#{usuario}</username>
         <password xsi:type=\"xsd:string\">#{contrasena}</password>
         <uuid xsi:type=\"xsd:string\">#{uuid}</uuid>
         <rfc_receptor xsi:type=\"xsd:string\">#{rfc_receptor}</rfc_receptor>
         <cert_pem xsi:type=\"xsd:string\">#{file_cer_pem}</cert_pem>
         <llave_pem xsi:type=\"xsd:string\">#{file_key_pem}</llave_pem>
      </urn:consultar_documento_relacionado>
   </soapenv:Body>
</soapenv:Envelope>^

# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo consultar_documento_relacionado
response = client.call(:consultar_documento_relacionado, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter el resultado de la consulta
resultado = documento.xpath("//resultado").text
puts resultado

# Obtener los documentos relacionados padres
uuids_padres = documento.xpath("//relacionados_padres").text
puts uuids_padres

# Obtener los documentos relacionados hijos
uuids_hijos = documento.xpath("//relacionados_hijos").text
puts uuids_hijos
