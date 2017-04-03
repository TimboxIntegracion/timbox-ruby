require 'base64'
require 'savon'

# Parametros para conexion al Webservice (URL de Pruebas)
wsdl_url = "https://staging.ws.timbox.com.mx/timbrado/wsdl"
usuario = "AAA010101000"
contrasena = "h6584D56fVdBbSmmnB"

archivo_xml = File.read("archivoXml.xml")
# Convertir la cadena del xml en base64
xml_base64 = Base64.strict_encode64(archivo_xml)

# Generar el Envelope
envelope = %Q^
  <soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
    <soapenv:Header/>
    <soapenv:Body>
      <urn:timbrar_cfdi soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
        <username xsi:type=\"xsd:string\">#{usuario}</username>
        <password xsi:type=\"xsd:string\">#{contrasena}</password>
        <sxml xsi:type=\"xsd:string\">#{xml_base64}</sxml>
    </urn:timbrar_cfdi>
    </soapenv:Body>
  </soapenv:Envelope>^

# Crear un cliente de savon para hacer la petición al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Llamar el metodo timbrar
response = client.call(:timbrar_cfdi, { "xml" => envelope })

# Extraer el xml timbrado desde la respuesta del WS
response = response.to_hash
xml_timbrado = response[:timbrar_cfdi_response][:timbrar_cfdi_result][:xml]

puts xml_timbrado

