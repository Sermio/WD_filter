# Configuración de Firma de la Aplicación

## Archivos de Firma

Los siguientes archivos contienen información sensible y **NO** deben subirse a Git:

- `android/key.properties` - Contiene las contraseñas del keystore
- `android/keystore/` - Directorio con el archivo de keystore
- `*.jks`, `*.keystore`, `*.p12`, `*.pem` - Archivos de clave en cualquier formato

## Configuración Actual

- **Keystore**: `android/keystore/worldshift_assistant.jks`
- **Alias**: `worldshift_assistant`
- **Validez**: 25 años
- **Algoritmo**: RSA 2048 bits

## Verificación de Seguridad

Para verificar que los archivos están siendo ignorados por Git:

```bash
git check-ignore android/key.properties android/keystore/worldshift_assistant.jks
```

## Generación del Keystore

El keystore se generó con el comando:

```bash
keytool -genkey -v -keystore android/keystore/worldshift_assistant.jks -keyalg RSA -keysize 2048 -validity 9125 -alias worldshift_assistant
```

## Importante

- **NUNCA** subas estos archivos a Git
- Mantén una copia de seguridad segura del keystore
- Si pierdes el keystore, no podrás actualizar la aplicación en Google Play Store
