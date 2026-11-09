# App de citas · Dra. Andrea Pérez

Sitio público + panel de seguimiento instalable (PWA), con cuentas **nuevas y separadas** de Chefitt:
GitHub (repo propio) → Cloudflare Pages (hosting) → Supabase (base de datos y login).

```
index.html      Sitio público con chatbot y formulario de cita
admin.html      Panel de la doctora (esta es la "app" que se instala)
config.js       URL y clave pública de Supabase (se llena una vez)
manifest.webmanifest, sw.js, icons/   Lo que hace instalable la app
supabase/schema.sql                   Tablas y permisos (RLS)
_headers        Cabeceras de seguridad para Cloudflare Pages
```

## Qué guarda y qué no

Se guarda: nombre, teléfono, servicio, fecha preferida, estado de la cita, fecha de cita y una nota corta.
**No** se guardan diagnósticos, historial clínico ni fotos. Si algún día se necesitan, hay que rediseñar con asesoría legal (LFPDPPP) antes.

## Pasos (una sola vez)

### 1. Supabase (cuenta nueva)
1. Entra con una cuenta de Supabase distinta a la de Chefitt y crea un proyecto nuevo (región cercana, p. ej. us-east).
2. **SQL Editor** → pega todo `supabase/schema.sql` → *Run*.
3. **Authentication → Providers → Email**: deja activo el acceso por enlace mágico. En **Sign In / Providers** desactiva *Allow new users to sign up* (nadie más debe poder crear cuentas).
4. **Authentication → Users → Add user → Send invitation** al correo de la doctora.
5. Cuando acepte la invitación, en el SQL Editor corre:
   ```sql
   insert into public.admins (user_id)
     select id from auth.users where lower(email) = lower('Dra.Andrea.Pere@gmail.com');
   ```
   (Confirma que el correo sea exactamente el de la doctora.)
6. **Settings → API Keys**: copia la *Project URL* y la clave **publishable** (`sb_publishable_…`). Pégalas en `config.js`. Supabase retirará las claves antiguas (anon/service_role) a inicios de 2027, por eso se usa la nueva. **Nunca** uses ni subas una clave *secret* ni la `service_role`.

### 2. GitHub
1. Crea un repo nuevo (privado o público; la clave publishable es pública por diseño).
2. Sube esta carpeta tal cual.

### 3. Cloudflare Pages
1. Workers & Pages → Create → Pages → conectar el repo de GitHub.
2. *Framework preset*: None. *Build command*: vacío. *Output directory*: `/` (raíz).
3. Publica. Tendrás una URL tipo `https://tu-proyecto.pages.dev`.

### 4. Volver a Supabase
**Authentication → URL Configuration**: pon la URL de Cloudflare como *Site URL* y agrega `https://tu-proyecto.pages.dev/admin.html` en *Redirect URLs*.

### 5. Instalar la app
Abre `https://tu-proyecto.pages.dev/admin.html` en el celular de la doctora, entra con su correo (le llega un enlace) y usa *Instalar app* (Android/Chrome) o *Compartir → Agregar a pantalla de inicio* (iPhone).

## Probar que está bien cerrado
- Sin sesión, desde la consola del navegador, un `select` a `solicitudes` debe devolver vacío o error de permisos.
- Con una cuenta que **no** esté en `admins`, el panel debe decir "Esta cuenta no tiene permiso".
- Enviar el formulario público debe crear una fila con estado `nueva`.

## Pendiente antes de entregar
- Cédula profesional, dirección completa y horarios en `index.html` (bloque `CONFIG`).
- Aviso de privacidad revisado por un asesor legal (hoy es un borrador).
- Dominio propio (opcional) y conectar el WhatsApp oficial si quieren chatbot dentro de WhatsApp.

## Si quieren un APK real
La PWA ya se instala como app. Si necesitan Play Store o notificaciones push, este mismo código se empaqueta con Capacitor o Bubblewrap (TWA) para generar el APK. Requiere cuenta de desarrollador de Google.
