require 'savon'
require 'base64'
require 'nokogiri'

# Parametros para la conexión al Webservice
wsdl_url = "http://localhost:3000/valida_cfdi/wsdl"
usuario = "AAA010101000"
contrasena = "h6584D56fVdBbSmmnB"

# Parametros para la validación del CFDI
file_xml = File.read('ejemplo_cfdi_33.xml')
xml = Base64.strict_encode64(file_xml)
external = "1"

envelope = %Q^<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:WashOut">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:validar_cfdi soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
         <username xsi:type="xsd:string">#{usuario}</username>
         <password xsi:type="xsd:string">#{contrasena}</password>
         <validar xsi:type="urn:comprobante">
            <!--Zero or more repetitions:-->
            <Comprobante xsi:type="urn:Comprobante">
               <external_id xsi:type="xsd:string">#{external}</external_id>
               <sxml xsi:type="xsd:string">#{xml}</sxml>
            </Comprobante>
         </validar>
      </urn:validar_cfdi>
   </soapenv:Body>
</soapenv:Envelope>^

# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo validar_cfdi
response = client.call(:validar_cfdi, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter el resultado del xml
acuse = documento.xpath("//resultados").text
puts acuse

