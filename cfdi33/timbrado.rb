require 'base64'
require 'savon'
require 'nokogiri'
require 'byebug'

def generar_sello(comprobante, path_llave, password_llave)
  comprobante = Nokogiri::XML(comprobante)
  comprobante = actualizar_fecha(comprobante)
  cadena = get_cadena_original(comprobante)
  
  #Generar digestion y sello
  private_key = OpenSSL::PKey::RSA.new(File.read(path_llave), password_llave)
  digester = OpenSSL::Digest::SHA256.new
  signature = private_key.sign(digester, cadena)
  sello = Base64.strict_encode64(signature)
  comprobante = actualizar_sello(comprobante, sello)
end

#Obtener cadena original
def get_cadena_original(xml)
  xslt = Nokogiri::XSLT(File.read("cadenaoriginal_3_3.xslt"))
  cadena = xslt.transform(xml)
  cadena.text.gsub("\n","")
end

#Actualizar la fecha del xml a la actual
def actualizar_fecha(comprobante)
  #Actualizar fecha del nodo Fecha
  node = comprobante.xpath('//@Fecha')[0]
  fecha = Time.now.strftime("%Y-%m-%dT%H:%M:%S")
  node.content = fecha
  comprobante
end

#Actualizar el sello del comprobante
def actualizar_sello(comprobante, sello)
  node = comprobante.xpath('//@Sello')[0]
  node.content = sello
  comprobante.to_xml
end

# Parametros para conexion al Webservice (URL de Pruebas)
wsdl_url = "https://staging.ws.timbox.com.mx/timbrado_cfdi40/wsdl"
usuario = ""
contrasena = ""

nombreArchivo ="ejemplo_cfdi_33.xml"
llave = "../IVD920810GU2.key.pem"
pass_llave = "12345678a"

archivo_xml = File.read(nombreArchivo)
archivo_xml = generar_sello(archivo_xml, llave, pass_llave)

#Guardar cambios al archivo
File.write(nombreArchivo, archivo_xml.to_s)

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


