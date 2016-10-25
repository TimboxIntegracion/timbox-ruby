require 'base64'
require 'savon'

#parametros para la conexión al Webservice
wsdl_url = "https://staging.ws.timbox.com.mx/timbrado/wsdl"
wsdl_username = "user_name"
wsdl_password = "password"

#parametros para la cancelación del CFDI
rfc = "IAD121214B34"
uuid = "A7A812CC-3B51-4623-A219-8F4173D061FE"
pfx_path = 'path_del_archivo/iad121214b34.pfx'
bin_file = File.binread(pfx_path)
pfx_base64 = Base64.strict_encode64(bin_file)
pfx_password = "12345678a"

#generar el Envelope para el metodo cancelar
envelope = %Q^
<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
   <soapenv:Header/>
   <soapenv:Body>
    <urn:cancelar_cfdi soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
       <username xsi:type=\"xsd:string\">#{wsdl_username}</username>
       <password xsi:type=\"xsd:string\">#{wsdl_password}</password>
       <rfcemisor xsi:type=\"xsd:string\">#{rfc}</rfcemisor>
       <uuids xsi:type=\"urn:uuids\">
          <uuid xsi:type=\"xsd:string\">#{uuid}</uuid>
       </uuids>
       <pfxbase64 xsi:type=\"xsd:string\">#{pfx_base64}</pfxbase64>
       <pfxpassword xsi:type=\"xsd:string\">#{pfx_password}</pfxpassword>
    </urn:cancelar_cfdi>
 </soapenv:Body>
</soapenv:Envelope>^

#crear un cliente de savon para hacer la conexión al WS, en produccion quital el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

#hacer el llamado al metodo cancelar_cfdi
response = client.call(:cancelar_cfdi, {"xml" => envelope})

doc = Nokogiri::XML(response.to_xml)

#obenter el acuse de cancelación
acuse = doc.xpath("//acuse_cancelacion").text

#obtener los estatus de los comprobantes cancelados
uuids_cancelados = doc.xpath("//comprobantes_cancelados").text
