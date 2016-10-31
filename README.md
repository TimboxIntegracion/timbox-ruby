# Ruby
Ejemplo con la integración al Webservice de Timbox

Se deberá hacer uso de las URL que hacen referencia al WSDL, en cada petición realizada:

- [Timbox Pruebas](https://staging.ws.timbox.com.mx/timbrado/wsdl)

- [Timbox Producción](https://sistema.timbox.com.mx/timbrado/wsdl)

Para integrar el Webservice al proyecto se requiere hacer uso del modulo Base64:

```
require 'base64'
```

También se requiere instalar la gema de [Savon](http://savonrb.com/):

```
gem install savon
```

##Timbrar CFDI
Para hacer una petición de timbrado de un CFDI, deberá enviar las credenciales asignadas, asi como el xml que desea timbrar convertido a una cadena en base64:
```
cadena_xml = File.read("path_xml/example.xml")
xml_base64 = Base64.strict_encode64(cadena_xml)
```
Crear el envelope de la petición SOAP en un string:
```
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
```
Con la gema de savon crear un cliente y hacer el llamado al método timbrar_cfdi enviándole el envelope generado con la información necesaria:

```
client = Savon.client(wsdl: wsdl_url, log: true)

#llamar el método timbrar
response = client.call(:timbrar_cfdi, {"xml" => envelope})

#extraer el xml timbrado desde la respuesta del WS
doc = Nokogiri::XML(response.to_xml)
xml_timbrado = doc.xpath("//timbrar_cfdi_result").text
```

##Cancelar CFDI
Para la cancelación son necesarias las credenciales asignadas, RFC del emisor, un arreglo de UUIDs, el archivo PFX convertido a cadena en base64 y el password del archivo PFX:
```
pfx_path = 'path_del_archivo/archivo.pfx'
bin_file = File.binread(pfx_path)
pfx_base64 = Base64.strict_encode64(bin_file)
```
Crear en envelope para la petición de cancelación:
```
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
```
Crear un cliente de `Savon` para hacer la petición de cancelación al webservice:
```
client = Savon.client(wsdl: wsdl_url, log: true)

#hacer el llamado al método cancelar_cfdi
response = client.call(:cancelar_cfdi, {"xml" => envelope})
doc = Nokogiri::XML(response.to_xml)

#obtener el acuse de cancelación
acuse = doc.xpath("//acuse_cancelacion").text

#obtener los estatus de los comprobantes cancelados
uuids_cancelados = doc.xpath("//comprobantes_cancelados").text
```

