require 'savon'
require 'nokogiri'

# Parametros para la conexión al Webservice
wsdl_url = "https://staging.ws.timbox.com.mx/cancelacion/wsdl"
usuario = "AAA010101000"
contrasena = "h6584D56fVdBbSmmnB"

# Parametros para la consulta de estatus del CFDI
rfc_emisor = "AAA010101AAA"
rfc_receptor = "IAD121214B34"

 # uuid con aceptacion
# uuid = "1CC8A552-D1C7-4496-8DD2-626C3C46A8DC"
# total = "7261.60"

# uuid sin aceptacion
uuid = "1316D4E5-37B8-4CF1-8259-3898E53C1AF1"
total = "1751.60"

envelope = %Q^<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:consultar_estatus soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
         <username xsi:type=\"xsd:string\">#{usuario}</username>
         <password xsi:type=\"xsd:string\">#{contrasena}</password>
         <uuid xsi:type=\"xsd:string\">#{uuid}</uuid>
         <rfc_emisor xsi:type=\"xsd:string\">#{rfc_emisor}</rfc_emisor>
         <rfc_receptor xsi:type=\"xsd:string\">#{rfc_receptor}</rfc_receptor>
         <total xsi:type=\"xsd:string\">#{total}</total>
      </urn:consultar_estatus>
   </soapenv:Body>
</soapenv:Envelope>^

# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo cancelar_cfdi
response = client.call(:consultar_estatus, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter el estado de cancelación
estado = documento.xpath("//estado").text
puts estado

# Obtener los estatus de los comprobantes cancelados
estatus_cancelacion = documento.xpath("//estatus_cancelacion").text
puts estatus_cancelacion

