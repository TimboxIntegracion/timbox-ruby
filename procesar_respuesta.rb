require 'savon'
require 'nokogiri'

# Parametros para la conexión al Webservice
wsdl_url = "https://staging.ws.timbox.com.mx/cancelacion/wsdl"
usuario = "AAA010101000"
contrasena = "h6584D56fVdBbSmmnB"

# Parametros para la cancelación del CFDI
rfc_emisor = "AAA010101AAA"
rfc_receptor = "IAD121214B34"
uuid = "43234877-36A8-4E5E-8AD3-385C5D51DDC5"
total = "1751.60"
file_cer_pem = File.read('../CSD01_AAA010101AAA.cer.pem')
file_key_pem = File.read('../CSD01_AAA010101AAA.key.pem')

# A(Aceptar la solicitud), R(Rechazar la solicitud)
respuesta = 'A'

envelope = %Q^<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:procesar_respuesta soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
         <username xsi:type=\"xsd:string\">#{usuario}</username>
         <password xsi:type=\"xsd:string\">#{contrasena}</password>
         <rfc_receptor xsi:type=\"xsd:string\">#{rfc_receptor}</rfc_receptor>
         <respuestas xsi:type=\"urn:respuestas\">
            <!--Zero or more repetitions:-->
            <folios_respuestas xsi:type=\"urn:folios_respuestas\">
               <uuid xsi:type=\"xsd:string\">#{uuid}</uuid>
               <rfc_emisor xsi:type=\"xsd:string\">#{rfc_emisor}</rfc_emisor>
               <total xsi:type=\"xsd:string\">#{total}</total>
               <respuesta xsi:type=\"xsd:string\">#{respuesta}</respuesta>
            </folios_respuestas>
         </respuestas>
         <cert_pem xsi:type=\"xsd:string\">#{file_cer_pem}</cert_pem>
         <llave_pem xsi:type=\"xsd:string\">#{file_key_pem}</llave_pem>
      </urn:procesar_respuesta>
   </soapenv:Body>
</soapenv:Envelope>^

# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo cancelar_cfdi
response = client.call(:procesar_respuesta, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter la respuesta de los folios
acuse = documento.xpath("//folios").text
puts acuse
