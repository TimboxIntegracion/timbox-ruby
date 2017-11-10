# Ruby
Ejemplo con la integración al Webservice de Timbox

Se deberá hacer uso de las URL que hacen referencia al WSDL, en cada petición realizada:

- [Timbox Pruebas](https://staging.ws.timbox.com.mx/timbrado_cfdi33/wsdl)

- [Timbox Producción](https://sistema.timbox.com.mx/timbrado_cfdi33/wsdl)

Para integrar el Webservice al proyecto se requiere hacer uso del modulo Base64:

```
require 'base64'
```

También se requiere instalar la gema de [Savon](http://savonrb.com/):

```
gem install savon
```

## Timbrar CFDI
### Generacion de Sello
Para generar el sello se necesita: la llave privada (.key) en formato PEM. También es necesario incluir el XSLT del SAT para obtener transformar el XML a la cadena original.

De la cadena original se obtiene el digest y luego se utiliza el digest y la llave privada para obtener el sello. Todo esto se realiza con comandos de OpenSSL.

Finalmente el sello es actualizado en el archivo XML para que pueda ser timbrado. Esto se logra mandando llamar el método de actualizarSello:
```
generar_sello(comprobante, path_llave, password_llave);
```
Para hacer una petición de timbrado de un CFDI, deberá enviar las credenciales asignadas, asi como el xml que desea timbrar convertido a una cadena en base64:
```
nombreArchivo ="ejemplo_cfdi_33.xml"
...
archivo_xml = File.read(nombreArchivo)
archivo_xml = generar_sello(archivo_xml, llave, pass_llave)
# Convertir la cadena del xml en base64
xml_base64 = Base64.strict_encode64(archivo_xml)
```
Crear el envelope de la petición SOAP en un string:
```
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
```
Con la gema de savon crear un cliente y hacer el llamado al método timbrar_cfdi enviándole el envelope generado con la información necesaria:

```
# Crear un cliente de savon para hacer la petición al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Llamar el metodo timbrar
response = client.call(:timbrar_cfdi, { "xml" => envelope })

# Extraer el xml timbrado desde la respuesta del WS
response = response.to_hash
xml_timbrado = response[:timbrar_cfdi_response][:timbrar_cfdi_result][:xml]

puts xml_timbrado
```

## Cancelar CFDI
Para la cancelación son necesarias las credenciales asignadas, RFC del emisor, un arreglo de UUIDs, el archivo PFX convertido a cadena en base64 y el password del archivo PFX:
```
pfx_path = 'archivoPfx.pfx'
bin_file = File.binread(pfx_path)
pfx_base64 = Base64.strict_encode64(bin_file)
```
Crear en envelope para la petición de cancelación:
```
# Generar el Envelope para el metodo cancelar
envelope = %Q^
<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
   <soapenv:Header/>
   <soapenv:Body>
    <urn:cancelar_cfdi soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
       <username xsi:type=\"xsd:string\">#{usuario}</username>
       <password xsi:type=\"xsd:string\">#{contrasena}</password>
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
# Crear un cliente de savon para hacer la conexión al WS, en produccion quital el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo cancelar_cfdi
response = client.call(:cancelar_cfdi, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter el acuse de cancelación
acuse = documento.xpath("//acuse_cancelacion").text
puts acuse

# Obtener los estatus de los comprobantes cancelados
uuids_cancelados = documento.xpath("//comprobantes_cancelados").text
puts uuids_cancelados
```

