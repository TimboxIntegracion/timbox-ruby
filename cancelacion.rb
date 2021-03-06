require 'savon'
require 'nokogiri'

# Parametros para la conexión al Webservice
wsdl_url = "https://staging.ws.timbox.com.mx/cancelacion/wsdl"
usuario = "AAA010101000"
contrasena = "h6584D56fVdBbSmmnB"

# Parametros para la cancelación del CFDI
rfc_emisor = "AAA010101AAA"
rfc_receptor = "IAD121214B34"

#  uuid con aceptacion
# uuid = "1CC8A552-D1C7-4496-8DD2-626C3C46A8DC"
# total = "7261.60"

# uuid sin aceptacion
uuid = "1316D4E5-37B8-4CF1-8259-3898E53C1AF1"
total = "1751.60"

file_cer_pem = File.read('CSD01_AAA010101AAA.cer.pem')
file_key_pem = File.read('CSD01_AAA010101AAA.key.pem')

envelope = %Q^<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:cancelar_cfdi soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
         <username xsi:type=\"xsd:string\">#{usuario}</username>
         <password xsi:type=\"xsd:string\">#{contrasena}</password>
         <rfc_emisor xsi:type=\"xsd:string\">#{rfc_emisor}</rfc_emisor>
         <folios xsi:type=\"urn:folios\">
            <!--Zero or more repetitions:-->
            <folio xsi:type=\"urn:folio\">
               <uuid xsi:type=\"xsd:string\">#{uuid}</uuid>
               <rfc_receptor xsi:type=\"xsd:string\">#{rfc_receptor}</rfc_receptor>
               <total xsi:type=\"xsd:string\">#{total}</total>
            </folio>
         </folios>
         <cert_pem xsi:type=\"xsd:string\">#{file_cer_pem}</cert_pem>
         <llave_pem xsi:type=\"xsd:string\">#{file_key_pem}</llave_pem>
      </urn:cancelar_cfdi>
   </soapenv:Body>^

# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo cancelar_cfdi
response = client.call(:cancelar_cfdi, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter el acuse de cancelación
acuse = documento.xpath("//acuse_cancelacion").text
puts acuse

# Obtener los estatus de los comprobantes cancelados
uuids_cancelados = documento.xpath("//folios").text
puts uuids_cancelados
