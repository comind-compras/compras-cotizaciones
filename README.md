# Compras · Cotizaciones (Comind)

App de una sola página (`index.html`) para gestionar compras y cotizaciones de materiales.
Los datos viven en tu navegador y se respaldan en **Supabase**, así los ves desde cualquier equipo.

## 1. Supabase (una sola vez)

1. Crea un proyecto en <https://supabase.com>.
2. **SQL Editor → New query**: pega el contenido de `supabase_setup.sql` y pulsa **Run**.
3. **Authentication → Users → Add user**: crea tu usuario (correo + contraseña) marcando *Auto Confirm User*.
   Si solo lo usará tu equipo, apaga el registro público en *Sign In / Providers → Allow new users to sign up*.
4. **Project Settings → API**: copia la **Project URL** y la clave **anon / publishable**.
   Nunca uses la clave `service_role` en esta app.

## 2. Primera subida de datos

1. Abre la versión con tus datos (`App_Cotizaciones_Materiales_v7.html`) en el mismo navegador donde ya la usabas.
   (Si no ves tus datos, en la versión anterior ve a *Respaldo → Descargar respaldo* y aquí usa *Importar respaldo*).
2. Ve a **Respaldo → Respaldo en la nube**, pega URL + clave, tu correo y contraseña, y pulsa **Conectar**.
3. Si la nube está vacía te preguntará si subes los datos de este equipo. Acepta.

Desde ahí, cada cambio se sube solo a los pocos segundos. En la barra superior verás el estado de la nube.

## 3. Otros equipos

Abre la app (ver GitHub Pages abajo), ve a **Respaldo**, conecta con los mismos datos y se descarga todo.
Si dos equipos editan a la vez, la app avisa y te deja elegir qué versión conservar; nunca pisa en silencio.

## 4. GitHub

- Sube **solo `index.html`**, `supabase_setup.sql` y este `README.md`.
  `index.html` viene **sin datos** (sin proveedores, correos ni compras), pensado para repos públicos.
- **No subas** `App_Cotizaciones_Materiales_v7.html` ni ningún respaldo `.json` / `.csv`: contienen tus datos.
  Si el repo es privado puedes subirlo, pero igual no hace falta.
- Para abrirla desde cualquier lugar: *Settings → Pages → Deploy from a branch → main / root*.
- Opcional: en `index.html` busca `CLOUD_DEFAULT` y escribe tu URL y clave anon, así en cada equipo
  solo tendrás que poner correo y contraseña. La clave anon es pública por diseño; lo que protege tus datos
  son las políticas de seguridad (RLS) del SQL y tu contraseña.

## 5. Recuperar una versión anterior

Tabla `app_state_history` (Table Editor): guarda una copia cada 6 horas (últimas 60).
Copia el JSON de la columna `data` a un archivo `.json` y úsalo en *Respaldo → Importar respaldo*.
