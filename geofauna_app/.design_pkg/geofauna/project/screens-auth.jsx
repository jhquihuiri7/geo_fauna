/* Auth screens: Login + Signup */

function LoginScreen({ onNav }) {
  return (
    <div className="bg-surface min-h-full relative" style={{ paddingBottom: 32 }}>
      {/* Decorative bg */}
      <div style={{
        position: "absolute", top: -120, right: -100, width: 320, height: 320,
        background: "color-mix(in oklab, var(--primary-fixed-dim) 30%, transparent)",
        filter: "blur(80px)", borderRadius: "50%", pointerEvents: "none",
      }} />
      <div style={{
        position: "absolute", bottom: -160, left: -120, width: 360, height: 360,
        background: "color-mix(in oklab, var(--tertiary-container) 40%, transparent)",
        filter: "blur(100px)", borderRadius: "50%", pointerEvents: "none",
      }} />

      <div className="flex flex-col items-center pt-12 px-6 relative">
        {/* Brand */}
        <div className="text-center mb-10">
          <div
            className="organic-gradient inline-flex items-center justify-center mb-5"
            style={{ width: 76, height: 76, borderRadius: 26, boxShadow: "0 12px 40px rgba(0,105,72,0.25)" }}
          >
            <Icon name="eco" fill className="text-[42px]" style={{ color: "#fff" }} />
          </div>
          <h1 className="text-[40px] font-black tracking-tighter text-on-surface leading-none">EcoGuía</h1>
          <p className="text-on-surface-variant font-bold tracking-[0.18em] uppercase text-[10px] mt-3 opacity-70">
            Conservation Archive &amp; Field Report
          </p>
        </div>

        {/* Card */}
        <div
          className="bg-sc-lowest w-full shadow-soft"
          style={{ borderRadius: 36, padding: 28 }}
        >
          <div className="mb-6">
            <h2 className="text-2xl font-extrabold text-on-surface tracking-tight">Acceso de Investigador</h2>
            <p className="text-on-surface-variant text-sm mt-1 leading-relaxed">
              Ingrese sus credenciales para acceder al archivo de monitoreo biológico.
            </p>
          </div>

          <form className="space-y-5" onSubmit={e => { e.preventDefault(); onNav("dashboard"); }}>
            <div>
              <Cap className="mb-2">Email de usuario</Cap>
              <TextField icon="alternate_email" type="email" placeholder="investigador@ecoguia.org" />
            </div>
            <div>
              <Cap action={<a className="text-[10px] font-extrabold tracking-[0.15em] uppercase text-primary">¿Olvidó su clave?</a>} className="mb-2">
                Clave de acceso
              </Cap>
              <TextField icon="lock" type="password" placeholder="••••••••" />
            </div>
            <button
              type="submit"
              className="organic-gradient w-full flex items-center justify-center gap-2 font-extrabold text-[15px]"
              style={{
                color: "#fff", height: 56, borderRadius: 9999,
                boxShadow: "0 8px 25px rgba(0,105,72,0.3)",
                marginTop: 28,
              }}
            >
              Iniciar Sesión <Icon name="arrow_forward" />
            </button>
          </form>

          <div className="mt-8 pt-6 text-center" style={{ borderTop: "1px solid color-mix(in oklab, var(--outline-variant) 40%, transparent)" }}>
            <p className="text-sm text-on-surface-variant mb-3">¿Aún no forma parte del equipo de monitoreo?</p>
            <button
              onClick={() => onNav("signup")}
              className="bg-secondary-container inline-flex items-center gap-2 font-extrabold text-sm text-on-secondary-container"
              style={{ padding: "12px 24px", borderRadius: 9999 }}
            >
              <Icon name="person_add" className="text-[18px]" />
              Solicitar Registro
            </button>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-8 mb-4 flex items-center justify-center gap-4 opacity-60">
          <div className="flex items-center gap-1.5">
            <Icon name="verified_user" className="text-[14px] text-outline" />
            <span className="text-[9px] font-extrabold tracking-[0.18em] uppercase text-outline">Encriptación Segura</span>
          </div>
          <div style={{ width: 3, height: 3, background: "var(--outline)", borderRadius: 99 }} />
          <div className="flex items-center gap-1.5">
            <Icon name="landscape" className="text-[14px] text-outline" />
            <span className="text-[9px] font-extrabold tracking-[0.18em] uppercase text-outline">Archipiélago Galápagos</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function SignupScreen({ onNav }) {
  return (
    <div className="bg-surface min-h-full relative" style={{ paddingBottom: 120 }}>
      <div style={{
        position: "absolute", top: 100, right: -80, width: 220, height: 220,
        background: "color-mix(in oklab, var(--primary) 8%, transparent)",
        filter: "blur(60px)", borderRadius: "50%", pointerEvents: "none",
      }} />
      <div style={{
        position: "absolute", bottom: 80, left: -100, width: 280, height: 280,
        background: "color-mix(in oklab, var(--tertiary-container) 30%, transparent)",
        filter: "blur(80px)", borderRadius: "50%", pointerEvents: "none",
      }} />

      {/* TopBar */}
      <header className="bg-surface flex items-center gap-3 px-5 py-3">
        <button onClick={() => onNav("login")} className="text-primary">
          <Icon name="arrow_back" />
        </button>
        <span className="text-lg font-black tracking-tight text-primary">EcoGuía</span>
      </header>

      <div className="px-6 relative">
        {/* Hero */}
        <div className="mb-8 pl-4" style={{ borderLeft: "4px solid var(--primary)" }}>
          <h1 className="text-[34px] font-black tracking-tighter text-on-surface leading-[1.05] mb-2">
            Registro de<br />Guardaparque
          </h1>
          <p className="text-on-surface-variant text-sm leading-relaxed max-w-xs">
            Inicie su sesión en el Archivo Orgánico para la preservación del ecosistema de Galápagos.
          </p>
        </div>

        {/* Card */}
        <div className="bg-sc-lowest shadow-soft relative overflow-hidden" style={{ borderRadius: 32, padding: 24 }}>
          <div style={{
            position: "absolute", top: -48, right: -48, width: 128, height: 128,
            background: "color-mix(in oklab, var(--primary) 8%, transparent)",
            borderRadius: "50%", filter: "blur(40px)",
          }} />

          <form className="space-y-5 relative">
            <Field cap="Tipo de Usuario" icon="account_circle">
              <Select value="Guía Naturalista" />
            </Field>
            <Field cap="Nombre Completo" icon="person">
              <input className="bg-transparent outline-none w-full text-[15px] text-on-surface placeholder:text-outline" placeholder="Ej. Dr. Julián Castro" />
            </Field>
            <Field cap="Correo Institucional" icon="mail">
              <input className="bg-transparent outline-none w-full text-[15px] text-on-surface placeholder:text-outline" placeholder="julian.castro@galapagos.gob.ec" />
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <Field cap="ID Guardaparque" icon="badge">
                <input className="bg-transparent outline-none w-full text-[13px] text-on-surface placeholder:text-outline" placeholder="GNPS-2024-00X" />
              </Field>
              <Field cap="Especialidad" icon="science">
                <Select value="Conservación Marina" />
              </Field>
            </div>
            <Field cap="Contraseña" icon="lock">
              <input type="password" className="bg-transparent outline-none w-full text-[15px] text-on-surface placeholder:text-outline" placeholder="••••••••••••" />
            </Field>

            <div className="flex items-start gap-3 px-2 pt-1">
              <input type="checkbox" className="mt-1 w-4 h-4 accent-emerald-700" defaultChecked />
              <p className="text-xs leading-relaxed text-on-surface-variant">
                Acepto el <span className="text-primary font-extrabold">Protocolo de Integridad de Datos</span> y los términos de uso para el monitoreo de biodiversidad de la Dirección del Parque Nacional Galápagos.
              </p>
            </div>

            <button
              type="button"
              onClick={() => onNav("dashboard")}
              className="organic-gradient w-full flex items-center justify-center gap-2 font-extrabold text-[15px]"
              style={{ color: "#fff", height: 56, borderRadius: 9999, boxShadow: "0 8px 25px rgba(0,105,72,0.3)", marginTop: 8 }}
            >
              Crear Cuenta <Icon name="chevron_right" />
            </button>
          </form>
        </div>

        {/* System status */}
        <div className="mt-6 flex items-center gap-3 px-2">
          <div className="bg-secondary-container flex items-center justify-center" style={{ width: 40, height: 40, borderRadius: 9999 }}>
            <span style={{ fontSize: 20 }}>🐢</span>
          </div>
          <div className="flex-1">
            <div className="text-[9px] font-extrabold uppercase tracking-[0.15em] text-outline">Estado del Sistema</div>
            <div className="text-sm font-bold text-primary">Operativo · Nodo Puerto Ayora</div>
          </div>
        </div>

        <p className="text-sm text-on-surface-variant text-center mt-6">
          ¿Ya es miembro? <button onClick={() => onNav("login")} className="text-primary font-extrabold">Iniciar Sesión</button>
        </p>
      </div>
    </div>
  );
}

function Field({ cap, icon, children }) {
  return (
    <div>
      <Cap className="mb-2">{cap}</Cap>
      <div className="bg-sc-low flex items-center gap-3" style={{ borderRadius: 9999, height: 52, padding: "0 18px" }}>
        {icon && <Icon name={icon} className="text-outline text-[18px]" />}
        <div className="flex-1">{children}</div>
      </div>
    </div>
  );
}

function Select({ value }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-[14px] text-on-surface font-medium">{value}</span>
      <Icon name="expand_more" className="text-outline" />
    </div>
  );
}

Object.assign(window, { LoginScreen, SignupScreen });
