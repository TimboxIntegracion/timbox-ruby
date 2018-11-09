# Ruby
Ejemplo con la integración al Webservice de Timbox

Se deberá hacer uso de las URL que hacen referencia al WSDL, en cada petición realizada:

- [Timbox Pruebas](https://staging.ws.timbox.com.mx/timbrado_cfdi33/wsdl)

- [Timbox Producción](https://sistema.timbox.com.mx/timbrado_cfdi33/wsdl)

Para integrar el Webservice al proyecto se requiere hacer uso del modulo Base64:

```
require 'base64'
require 'savon'
require 'nokogiri'
```

También se requiere instalar la gema de [Savon](http://savonrb.com/) y [nokogiri](http://www.nokogiri.org/):

```
gem install savon
```

## Timbrar CFDI
### Generación de Sello
Para generar el sello se necesita: la llave privada (.key) en formato PEM y el XSLT del SAT (cadenaoriginal_3_3.xslt).El XSLT del SAT se utiliza para poder transformar el XML y obtener la cadena original.

La cadena original se utiliza para obtener el digest, usando las funciones de la librería de criptografía, luego se utiliza el digest y la llave privada para obtener el sello. Todo esto se realiza utilizando la libreria de OpenSSL.

Una vez generado el sello, se actualiza en el XML para que este sea codificado y enviado al servicio de timbrado.
Esto se logra mandando llamar el método de generar_sello:
```
generar_sello(comprobante, path_llave, password_llave);
```
### Timbrado
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
Con la gema de savon se debe crear un cliente y hacer el llamado al método timbrar_cfdi enviándo el envelope generado con la información necesaria:

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
Para la cancelación son necesarios el certificado y llave, en formato pem que corresponde al emisor del comprobante:
```
file_cer_pem = File.read('CSD01_AAA010101AAA.cer.pem')
file_key_pem = File.read('CSD01_AAA010101AAA.key.pem')
```
Crear en envelope para la petición de cancelación:
```
# Generar el Envelope para el metodo cancelar
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
            </folio>
         </folios>
         <cert_pem xsi:type=\"xsd:string\">#{file_cer_pem}</cert_pem>
         <llave_pem xsi:type=\"xsd:string\">#{file_key_pem}</llave_pem>
      </urn:cancelar_cfdi>
   </soapenv:Body>^
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
## Consultar Estatus CFDI
Para la consulta de estatus de CFDI solo es necesario generar la petición de consulta,
Crear el envelope de la petición SOAP en un string:

```
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
```
Crear un cliente de Savon para hacer la petición de consulta al webservice:

```
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
```

##Consultar Peticiones Pendientes
Para la consulta de peticiones pendientes son necesarios el certificado y llave, en formato pem que corresponde al emisor del comprobante:
```
file_cer_pem = File.read('CSD01_AAA010101AAA.cer.pem')
file_key_pem = File.read('CSD01_AAA010101AAA.key.pem')
```

Crear en envelope para la petición de consultas pendientes:
```
envelope = %Q^<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:WashOut\">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:consultar_peticiones_pendientes soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
         <username xsi:type=\"xsd:string\">#{usuario}</username>
         <password xsi:type=\"xsd:string\">#{contrasena}</password>
         <rfc_receptor xsi:type=\"xsd:string\">#{rfc_receptor}</rfc_receptor>
         <cert_pem xsi:type=\"xsd:string\">#{file_cer_pem}</cert_pem>
         <llave_pem xsi:type=\"xsd:string\">#{file_key_pem}</llave_pem>
      </urn:consultar_peticiones_pendientes>
   </soapenv:Body>
</soapenv:Envelope>^
```
Crear un cliente de `Savon` para hacer la petición de consulta al webservice:
```
# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo cancelar_cfdi
response = client.call(:consultar_peticiones_pendientes, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter el estado de las peticiones pendientes
cofigo_de_estado = documento.xpath("//codestatus").text
puts cofigo_de_estado

# Obtener los uuids pendientes
uuids = documento.xpath("//uuids").text
puts uuids
```

## Procesar Respuesta
Para realizar la petición de aceptación/rechazo de la solicitud de cancelación son necesarios el certificado y llave, en formato pem que corresponde al emisor del comprobante:
```
file_cer_pem = File.read('CSD01_AAA010101AAA.cer.pem')
file_key_pem = File.read('CSD01_AAA010101AAA.key.pem')
```

Crear en envelope para la petición de consultas pendientes:
```
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
```
Crear un cliente de `Savon` para hacer la petición de aceptación/rechazo al webservice:
```
# Crear un cliente de savon para hacer la conexión al WS, en produccion quitar el "log: true"
client = Savon.client(wsdl: wsdl_url, log: true)

# Hacer el llamado al metodo cancelar_cfdi
response = client.call(:procesar_respuesta, { "xml" => envelope })

documento = Nokogiri::XML(response.to_xml)

# Obenter la respuesta de los folios
acuse = documento.xpath("//folios").text
puts acuse

```