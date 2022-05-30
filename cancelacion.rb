require 'savon'
require 'nokogiri'

# Parametros para la conexión al Webservice
wsdl_url = "https://staging.ws.timbox.com.mx/cancelacion/wsdl"
usuario = "ZAHS9608015W4"
contrasena = "12345678"

# Parametros para la cancelación del CFDI
rfc_emisor = "IVD920810GU2"
rfc_receptor = "IAD121214B34"

# Motivos de Cancelación (Código - Descripción)
#  01    -    Comprobante emitido con errores con relación
#  02    -    Comprobante emitido con errores sin relación
#  03    -    No se llevó a cabo la operación
#  04    -    Operación nominativa relacionada en la factura global


#  uuid con motivo 01
uuid = "CF741B8A-A398-412E-BC97-6D1AE4B10069"
total = "7261.60"
motivo = "01"
folio_sustituto = "8D4B79A4-B17A-4B4B-9220-9225F73B8945"

#  uuid con motivo 02, 03, 04
#uuid = "1CC8A552-D1C7-4496-8DD2-626C3C46A8DC"
#total = "7261.60"
#motivo = "02" #motivo = "03"  #motivo = "04"
#folio_sustituto = ""


file_cer_pem = File.read('IVD920810GU2.cer.pem')
file_key_pem = File.read('IVD920810GU2.key.pem')

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
            <motivo xsi:type=\"xsd:string\">#{motivo}</motivo>
            <folio_sustituto xsi:type=\"xsd:string\">#{folio_sustituto}</folio_sustituto>
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
