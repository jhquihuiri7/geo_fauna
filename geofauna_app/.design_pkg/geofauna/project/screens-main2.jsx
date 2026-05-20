/* Dashboard + Perfil */

function DashboardScreen({ onNav }) {
  return (
    <div className="bg-surface min-h-full" style={{ paddingBottom: 120 }}>
      <TopBar
        title="EcoGuía Galápagos"
        leading={
          <button className="flex items-center justify-center" style={{ width: 40, height: 40, borderRadius: 9999, background: "var(--surface-container-low)" }}>
            <Icon name="menu" />
          </button>
        }
        trailing={<Avatar tone="forest" emoji="🦫" size={40} status="on" />}
      />

      <main className="px-5 pt-5 space-y-8">
        {/* Weather mini */}
        <section>
          <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-1">Estado del Tiempo</div>
          <h1 className="text-3xl font-black text-on-surface tracking-tighter leading-none">Puerto Ayora, SC</h1>
          <div className="flex items-center gap-1.5 mt-1.5 text-on-surface-variant text-sm">
            <Icon name="location_on" className="text-[16px] text-primary" />
            <span>Isla Santa Cruz · Estación Charles Darwin</span>
          </div>
          <div className="bg-sc-lowest shadow-card mt-4 flex items-center gap-4" style={{ borderRadius: 28, padding: "14px 18px" }}>
            <div style={{ fontSize: 32 }}>☀️</div>
            <div>
              <div className="text-2xl font-black tracking-tight text-on-surface leading-none">28°C</div>
              <div className="text-[10px] font-extrabold uppercase tracking-widest text-on-surface-variant mt-1">Humedad 64% · UV 11+</div>
            </div>
          </div>
        </section>

        {/* Map */}
        <section className="relative overflow-hidden topo-map" style={{ borderRadius: 32, minHeight: 240 }}>
          <div className="absolute top-4 left-4 glass flex items-center gap-2"
            style={{ padding: "8px 14px", borderRadius: 9999 }}>
            <Icon name="location_on" fill className="text-primary text-[16px]" />
            <span className="text-xs font-extrabold text-on-surface">12 Guías Activos</span>
            <span className="ml-2 text-[9px] font-extrabold tracking-widest uppercase text-on-surface-variant flex items-center gap-1">
              <span style={{ width: 6, height: 6, borderRadius: 99, background: "#22c55e" }} />
              Monitoreo en Vivo
            </span>
          </div>

          {/* Faux pins */}
          {[
            { top: "30%", left: "32%", tone: "primary", emoji: "🐢" },
            { top: "44%", left: "58%", tone: "tertiary", emoji: "🦎" },
            { top: "62%", left: "44%", tone: "primary", emoji: "🦅" },
            { top: "52%", left: "22%", tone: "secondary", emoji: "📍" },
          ].map((p, i) => (
            <div key={i} style={{
              position: "absolute", top: p.top, left: p.left,
              width: 36, height: 36, borderRadius: 9999,
              background: "rgba(255,255,255,.9)", display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 18, boxShadow: "0 4px 12px rgba(0,0,0,.3)",
              border: "3px solid var(--primary)",
            }}>{p.emoji}</div>
          ))}

          <button className="absolute bottom-4 right-4 bg-primary text-on-primary flex items-center gap-2 font-extrabold text-xs"
            style={{ padding: "10px 16px", borderRadius: 9999, boxShadow: "0 6px 18px rgba(0,0,0,.3)" }}>
            <Icon name="open_in_full" className="text-[14px]" />
            Expandir Mapa
          </button>
        </section>

        {/* Centro de Reconocimiento */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <div>
              <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-1">Prestigio e Impacto</div>
              <h2 className="text-2xl font-black tracking-tight text-on-surface">Centro de Reconocimiento</h2>
            </div>
            <a className="text-xs font-extrabold text-primary">Perfil Completo</a>
          </div>

          <div className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: "20px 16px" }}>
            <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant text-center mb-4">Top Contribuidores</div>
            <div className="grid grid-cols-3 gap-3 items-end">
              <Podium rank={2} icon="military_tech" iconColor="#9ca3af" name="Elena R." pts="982" tone="slate" emoji="👩‍🔬" />
              <Podium rank={1} icon="emoji_events" iconColor="#f59e0b" name="Mateo L." pts="1,245" tone="primary" emoji="🧑‍🌾" highlight />
              <Podium rank={3} icon="workspace_premium" iconColor="#c87f5b" name="Carlos J." pts="856" tone="forest" emoji="🦫" />
            </div>
          </div>
        </section>

        {/* Líderes por categoría */}
        <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: 18 }}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-extrabold text-on-surface">Líderes por Categoría</h3>
            <Chip tone="emerald">Actualizado hoy</Chip>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <LeaderCard tone="primary" name="Elena R." role="Campeón" cat="Fauna" pts="421 pts" emoji="👩‍🔬" />
            <LeaderCard tone="tertiary" name="Mateo L." role="Experto" cat="Flora" pts="388 pts" emoji="🧑‍🌾" />
            <LeaderCard tone="warning" name="Carlos J." role="Avanzado" cat="Incidentes" pts="254 pts" emoji="🦫" />
            <LeaderCard tone="primary" name="Sofía M." role="Campeón" cat="Basura" pts="512 pts" emoji="👩" />
          </div>
        </section>

        {/* Monitor */}
        <section>
          <div className="flex items-end justify-between mb-3 px-1">
            <div>
              <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-1">Monitor de Comunidad</div>
              <h2 className="text-2xl font-black tracking-tight text-on-surface">Análisis de Datos</h2>
            </div>
            <a className="text-xs font-extrabold text-primary flex items-center gap-1">Ver reporte <Icon name="arrow_forward" className="text-[14px]" /></a>
          </div>

          <div className="bg-sc-lowest shadow-card" style={{ borderRadius: 28, padding: 18 }}>
            <div className="flex items-end justify-between mb-3">
              <div>
                <div className="text-[10px] font-extrabold uppercase tracking-widest text-on-surface-variant">Avistamientos totales</div>
                <div className="text-3xl font-black text-on-surface tracking-tighter mt-1">15,402</div>
              </div>
              <div className="text-right">
                <Chip tone="emerald">+15.2%</Chip>
                <div className="text-[10px] text-on-surface-variant mt-1">Vs. mes anterior</div>
              </div>
            </div>
            <div className="flex items-end justify-between gap-1.5 mt-3" style={{ height: 80 }}>
              {[34, 42, 38, 56, 48, 70, 92].map((h, i) => (
                <div key={i} style={{ flex: 1, height: h + "%" }} className={i === 6 ? "bar-fill" : "bar-fade"} />
              ))}
            </div>
          </div>

          <div className="bg-sc-lowest shadow-card mt-4 flex items-center justify-between" style={{ borderRadius: 28, padding: 18 }}>
            <div>
              <div className="text-[10px] font-extrabold uppercase tracking-widest text-on-surface-variant">Precisión de Datos</div>
              <div className="text-3xl font-black tracking-tighter mt-1 text-on-surface">94.2%</div>
              <div className="flex items-center gap-1 mt-1">
                <Icon name="check_circle" fill className="text-[14px] text-primary" />
                <span className="text-[11px] text-on-surface-variant">Calidad de grado científico</span>
              </div>
            </div>
            <DonutBig value={94} />
          </div>

          {/* Especies con mayor impacto */}
          <div className="bg-sc-lowest shadow-card mt-4" style={{ borderRadius: 28, padding: 18 }}>
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-sm font-extrabold text-on-surface">Especies con Mayor Impacto</h4>
              <span className="text-[9px] font-extrabold tracking-widest uppercase text-outline">Top Reportadas</span>
            </div>
            <div className="space-y-3">
              <SpeciesRow name="Tortuga Gigante" emoji="🐢" pts="4,201" pct={92} tone="primary" />
              <SpeciesRow name="Iguana Marina" emoji="🦎" pts="3,120" pct={68} tone="emerald" />
              <SpeciesRow name="Piquero Patas Azules" emoji="🐦" pts="2,840" pct={60} tone="tertiary" />
              <SpeciesRow name="Lobo Marino" emoji="🦭" pts="1,950" pct={42} tone="warning" />
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}

function Podium({ rank, icon, iconColor, name, pts, tone, emoji, highlight }) {
  const ranks = { 1: 70, 2: 50, 3: 40 };
  return (
    <div className="flex flex-col items-center">
      <Icon name={icon} fill className="text-[28px] mb-2" style={{ color: iconColor }} />
      <Avatar size={56} tone={tone} emoji={emoji} />
      <div className="text-[11px] font-extrabold text-on-surface mt-2 text-center">{name}</div>
      <div className={"font-black tracking-tighter mt-0.5 " + (highlight ? "text-primary text-xl" : "text-on-surface text-base")}>{pts}</div>
      <div className="text-[8px] font-extrabold uppercase tracking-widest text-outline">Registros</div>
    </div>
  );
}

function LeaderCard({ name, role, cat, pts, tone, emoji }) {
  return (
    <div className="bg-sc-low" style={{ borderRadius: 24, padding: 14 }}>
      <div className="flex items-center gap-3">
        <Avatar size={40} tone={tone === "warning" ? "sand" : tone === "tertiary" ? "blue" : "primary"} emoji={emoji} />
        <div className="min-w-0">
          <div className="text-sm font-extrabold text-on-surface truncate">{name}</div>
          <Chip tone={tone === "warning" ? "warning" : tone === "tertiary" ? "tertiary" : "emerald"} size="sm">{role}</Chip>
        </div>
      </div>
      <div className="mt-3 flex items-end justify-between">
        <span className="text-[10px] font-extrabold uppercase tracking-widest text-on-surface-variant">{cat}</span>
        <span className="text-sm font-black text-on-surface">{pts}</span>
      </div>
    </div>
  );
}

function DonutBig({ value }) {
  const r = 28, c = 2 * Math.PI * r;
  return (
    <svg width={72} height={72} viewBox="0 0 72 72">
      <circle cx="36" cy="36" r={r} stroke="var(--surface-container-high)" strokeWidth="8" fill="none" />
      <circle cx="36" cy="36" r={r} stroke="var(--primary)" strokeWidth="8" fill="none"
        strokeDasharray={c} strokeDashoffset={c * (1 - value / 100)}
        strokeLinecap="round" transform="rotate(-90 36 36)" />
      <text x="36" y="38" textAnchor="middle" dominantBaseline="middle"
        fontSize="11" fontWeight="900" fill="var(--on-surface)">{value}%</text>
    </svg>
  );
}

function SpeciesRow({ name, emoji, pts, pct, tone }) {
  const colors = {
    primary: "var(--primary)",
    emerald: "#10b981",
    tertiary: "var(--tertiary)",
    warning: "#f59e0b",
  };
  return (
    <div>
      <div className="flex items-center justify-between mb-1.5">
        <div className="flex items-center gap-2">
          <span style={{ fontSize: 16 }}>{emoji}</span>
          <span className="text-[12px] font-extrabold uppercase tracking-wide text-on-surface">{name}</span>
        </div>
        <span className="text-[11px] font-extrabold text-on-surface-variant">{pts} sightings</span>
      </div>
      <div className="bg-sc" style={{ height: 6, borderRadius: 99 }}>
        <div style={{ width: pct + "%", height: "100%", background: colors[tone], borderRadius: 99 }} />
      </div>
    </div>
  );
}

// ---------- PERFIL ----------
function PerfilScreen({ onNav }) {
  return (
    <div className="bg-surface min-h-full" style={{ paddingBottom: 120 }}>
      <TopBar
        title="Mi Bitácora"
        leading={<Avatar size={40} tone="forest" emoji="🦫" status="on" />}
        trailing={<Icon name="cloud_done" fill className="text-primary" />}
      />

      <main className="px-6 pt-4 space-y-6">
        <section>
          <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-1">Perfil del Agente</div>
          <h1 className="text-[40px] font-black text-on-surface tracking-tighter leading-none">Carlos Jaramillo</h1>
          <p className="text-on-surface-variant text-sm mt-2">Guía Nacional GN-2024</p>
        </section>

        {/* Digital ID Card */}
        <section className="organic-gradient relative overflow-hidden" style={{ borderRadius: 32, padding: 24, color: "#fff" }}>
          <div className="dot-pattern" style={{ position: "absolute", inset: 0, opacity: 0.4 }} />
          <div className="relative">
            <div className="flex items-start justify-between gap-4">
              <div className="flex-1">
                <div className="text-[10px] font-extrabold uppercase tracking-widest opacity-80">Identificación Digital</div>
                <h2 className="text-lg font-extrabold mt-1 leading-tight">Parque Nacional<br />Galápagos</h2>
                <div className="grid grid-cols-2 gap-4 mt-5 text-[11px]">
                  <div>
                    <div className="opacity-70 font-extrabold uppercase tracking-widest text-[9px]">Sector</div>
                    <div className="font-extrabold mt-0.5">Isla Santa Cruz</div>
                  </div>
                  <div>
                    <div className="opacity-70 font-extrabold uppercase tracking-widest text-[9px]">Rango</div>
                    <div className="font-extrabold mt-0.5">Especialista III</div>
                  </div>
                  <div>
                    <div className="opacity-70 font-extrabold uppercase tracking-widest text-[9px]">Asignado</div>
                    <div className="font-extrabold mt-0.5">Charles Darwin</div>
                  </div>
                  <div>
                    <div className="opacity-70 font-extrabold uppercase tracking-widest text-[9px]">ID</div>
                    <div className="font-extrabold mt-0.5">8829-XJ-2024</div>
                  </div>
                </div>
                <div className="mt-4 inline-flex items-center gap-1.5 bg-white/15 px-3 py-1" style={{ borderRadius: 9999 }}>
                  <span style={{ width: 6, height: 6, borderRadius: 99, background: "#86efac" }} />
                  <span className="text-[10px] font-extrabold tracking-widest uppercase">Activo</span>
                </div>
              </div>

              <div className="qr-art" style={{ width: 100, height: 100, borderRadius: 18, flexShrink: 0 }} />
            </div>
          </div>
        </section>

        {/* Stats grid */}
        <section>
          <div className="grid grid-cols-3 gap-3">
            <StatCell icon="visibility" label="Avistamientos" value="1,204" />
            <StatCell icon="eco" label="Especies" value="87" />
            <StatCell icon="verified" label="Precisión" value="98%" />
            <StatCell icon="timer" label="En Campo" value="42h" />
            <StatCell icon="map" label="Recorrido" value="482km" />
            <StatCell icon="workspace_premium" label="Destacado" value="P. Carola" small />
          </div>
        </section>

        {/* Mi muro */}
        <section>
          <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-2">Mi Muro de Avistamiento</div>
          <div className="flex gap-5 mb-4">
            <button className="text-xs font-extrabold relative text-primary" style={{ paddingBottom: 6 }}>
              Recientes
              <span style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 2, borderRadius: 99, background: "var(--primary)" }} />
            </button>
            <button className="text-xs font-extrabold text-outline">Populares</button>
          </div>

          <div className="space-y-3">
            <MiniSighting emoji="🐢" name="Tortuga Gigante" place="Reserva El Chato" likes="24" comments="8" tone={3} />
            <MiniSighting emoji="🐦" name="Piquero Patas Azules" place="Playa de los Perros" likes="18" comments="5" tone={2} />
          </div>
        </section>

        <section className="space-y-3">
          <button onClick={() => onNav("settings")} className="w-full bg-sc-low flex items-center justify-between" style={{ borderRadius: 9999, padding: "16px 22px" }}>
            <span className="flex items-center gap-3">
              <Icon name="settings" className="text-on-surface" />
              <span className="font-extrabold text-on-surface text-sm">Configuración de Cuenta</span>
            </span>
            <Icon name="chevron_right" className="text-outline" />
          </button>
          <button onClick={() => onNav("integridad")} className="w-full bg-sc-low flex items-center justify-between" style={{ borderRadius: 9999, padding: "16px 22px" }}>
            <span className="flex items-center gap-3">
              <Icon name="shield" className="text-on-surface" />
              <span className="font-extrabold text-on-surface text-sm">Protocolo de Integridad de Datos</span>
            </span>
            <Icon name="chevron_right" className="text-outline" />
          </button>
          <button className="w-full bg-error-container flex items-center justify-center gap-2 text-error" style={{ borderRadius: 9999, padding: "16px 22px" }}>
            <Icon name="logout" />
            <span className="font-extrabold text-sm tracking-widest uppercase">Cerrar Sesión</span>
          </button>
        </section>
      </main>
    </div>
  );
}

function StatCell({ icon, label, value, small }) {
  return (
    <div className="bg-sc-lowest shadow-card flex flex-col items-center text-center" style={{ borderRadius: 24, padding: "16px 10px" }}>
      <div className="flex items-center justify-center mb-2" style={{
        width: 36, height: 36, borderRadius: 9999,
        background: "color-mix(in oklab, var(--primary) 12%, transparent)",
      }}>
        <Icon name={icon} className="text-primary text-[18px]" />
      </div>
      <div className={(small ? "text-sm " : "text-xl ") + "font-black text-on-surface tracking-tight"}>{value}</div>
      <div className="text-[9px] font-extrabold uppercase tracking-widest text-on-surface-variant mt-1">{label}</div>
    </div>
  );
}

function MiniSighting({ emoji, name, place, likes, comments, tone }) {
  return (
    <div className="bg-sc-lowest shadow-card flex items-center gap-4 p-3" style={{ borderRadius: 24 }}>
      <div style={{ width: 72, height: 72, borderRadius: 20, overflow: "hidden", flexShrink: 0 }}>
        <Photo tone={tone} label="" aspect="1/1" emoji={emoji} />
      </div>
      <div className="flex-1">
        <div className="font-extrabold text-on-surface text-sm">{name}</div>
        <div className="flex items-center gap-1.5 text-[11px] text-on-surface-variant mt-0.5">
          <Icon name="location_on" className="text-[12px] text-primary" />
          <span>{place}</span>
        </div>
        <div className="flex items-center gap-4 mt-2 text-on-surface-variant text-[12px]">
          <span className="flex items-center gap-1"><Icon name="favorite" className="text-[14px]" />{likes}</span>
          <span className="flex items-center gap-1"><Icon name="chat_bubble" className="text-[14px]" />{comments}</span>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { DashboardScreen, PerfilScreen });
