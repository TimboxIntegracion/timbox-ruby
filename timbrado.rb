require 'base64'
require 'savon'

#parametros para conexion al Webservice (URL de Pruebas)
wsdl_url = "https://staging.ws.timbox.com.mx/timbrado/wsdl"
wsdl_username = "user_name"
wsdl_password = "password"

#convertir la cadena del xml en base64
xml_base64 = Base64.strict_encode64(cadena_xml)

#generar el Envelope
envelope = %Q^
  <soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
    <soapenv:Header/>
    <soapenv:Body>
      <urn:timbrar_cfdi soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
        <username xsi:type=\"xsd:string\">#{wsdl_username}</username>
        <password xsi:type=\"xsd:string\">#{wsdl_password}</password>
        <sxml xsi:type=\"xsd:string\">#{xml_base64}</sxml>
    </urn:timbrar_cfdi>
    </soapenv:Body>
  </soapenv:Envelope>^

#crear un cliente de savon para hacer la petición al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

#llamar el metodo timbrar
response = client.call(:timbrar_cfdi, {"xml" => envelope})

#extraer el xml timbrado desde la respuesta del WS
doc = Nokogiri::XML(response.to_xml)
xml_timbrado = doc.xpath("//timbrar_cfdi_result").text


