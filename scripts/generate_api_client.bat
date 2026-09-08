@echo off
setlocal
set SPEC_PATH=%1
if "%SPEC_PATH%"=="" set SPEC_PATH=specs\openapi\api-spec.json
set OUTPUT_DIR=lib\infrastructure\api\generated

if not exist "%SPEC_PATH%" (
  echo Error: OpenAPI specification not found at %SPEC_PATH%
  exit /b 1
)

echo Generating Dart API Client into %OUTPUT_DIR%...
call npx --yes @openapitools/openapi-generator-cli generate -i "%SPEC_PATH%" -g dart -o "%OUTPUT_DIR%" --global-property=apiTests=false,modelTests=false,apiDocs=false,modelDocs=false
echo API Client generated successfully.
