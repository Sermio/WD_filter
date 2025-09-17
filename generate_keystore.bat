@echo off
echo ========================================
echo    Generador de Keystore para Android
echo    WorldShift Assistant
echo ========================================
echo.

echo Este script generara un keystore para firmar tu aplicacion Android.
echo.
echo IMPORTANTE: Guarda bien las contraseñas que introduzcas, las necesitaras
echo para futuras actualizaciones de la aplicacion.
echo.

set /p store_password="Introduce la contraseña del keystore (minimo 6 caracteres): "
set /p key_password="Introduce la contraseña de la clave (minimo 6 caracteres): "

echo.
echo Generando keystore...

keytool -genkey -v -keystore android\keystore\worldshift_assistant.jks -keyalg RSA -keysize 2048 -validity 10000 -alias worldshift_assistant_key -storepass %store_password% -keypass %key_password% -dname "CN=WorldShift Assistant, OU=Development, O=SMT Dev, L=Madrid, S=Madrid, C=ES"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    Keystore generado exitosamente!
    echo ========================================
    echo.
    echo Archivo generado: android\keystore\worldshift_assistant.jks
    echo.
    echo Ahora actualiza el archivo android\key.properties con las contraseñas:
    echo storePassword=%store_password%
    echo keyPassword=%key_password%
    echo keyAlias=worldshift_assistant_key
    echo storeFile=../keystore/worldshift_assistant.jks
    echo.
    echo IMPORTANTE: Guarda este archivo en un lugar seguro!
    echo.
    pause
) else (
    echo.
    echo Error generando el keystore. Verifica que Java este instalado.
    echo.
    pause
)


