let DATA = null;

async function init() {
  try {
    const res = await fetch('data.json');
    DATA = await res.json();
  } catch (e) {
    document.getElementById('overview').innerHTML = `
      <div style="padding:40px;color:var(--text-muted);text-align:center;">
        <h2 style="color:var(--accent-red);">Daten konnten nicht geladen werden</h2>
        <p>fetch() funktioniert nicht mit file:// — oeffne die Datei ueber einen lokalen Server:</p>
        <pre style="text-align:left;display:inline-block;margin-top:16px;padding:16px;background:var(--bg-secondary);border-radius:8px;">cd ~/MDM/harness-app && python3 -m http.server 8042</pre>
        <p style="margin-top:12px;">Dann oeffne <code>http://localhost:8042</code></p>
      </div>
    `;
    return;
  }
  renderNav();
  showView('overview');
}

function renderStats() {
  const stats = [
    { value: DATA.agents.length, label: 'Agenten' },
    { value: DATA.skills.length, label: 'Skills' },
    { value: DATA.rules.length, label: 'Rules' },
    { value: DATA.hooks.length, label: 'Hooks' },
    { value: DATA.workspace.repos.filter(r => r.status === 'aktiv').length, label: 'Aktive Repos' },
    { value: DATA.architecture.extensions.length, label: 'Extensions' }
  ];
  return stats.map(s => `
    <span class="stat"><span class="stat-value">${s.value}</span> ${s.label}</span>
  `).join('');
}

function renderNav() {
  document.querySelectorAll('.nav button').forEach(btn => {
    btn.addEventListener('click', () => showView(btn.dataset.view));
  });
}

function showView(id) {
  document.querySelectorAll('.nav button').forEach(b => b.classList.toggle('active', b.dataset.view === id));
  document.querySelectorAll('.view').forEach(v => v.classList.toggle('active', v.id === id));

  switch (id) {
    case 'overview': renderOverview(); break;
    case 'agents': renderAgents(); break;
    case 'workflows': renderWorkflows(); break;
    case 'skills': renderSkills(); break;
    case 'architecture': renderArchitecture(); break;
    case 'rules': renderRulesHooks(); break;
    case 'improvements': renderImprovements(); break;
  }
}

/* ── Overview ─────────────────────────────────────────── */

function renderOverview() {
  const el = document.getElementById('overview');
  el.innerHTML = `
    <div class="stats">${renderStats()}</div>
    <h2 class="section-header">Repos</h2>
    <div class="cards">
      ${DATA.workspace.repos.map(r => `
        <div class="card">
          <div class="card-header">
            <h3>${r.name}</h3>
            <span class="badge badge-${r.status === 'aktiv' ? 'theme' : 'haiku'}">${r.status}</span>
          </div>
          <div class="card-role">${r.tech}</div>
          <div class="card-meta">
            <span>${r.path}</span>
            <span>${r.git}</span>
            ${r.deploy ? `<span>${r.deploy}</span>` : ''}
            ${r.store ? `<span>Store: ${r.store}</span>` : ''}
          </div>
        </div>
      `).join('')}
    </div>

    <h2 class="section-header">Agenten nach Scope</h2>
    <div class="cards">
      ${['theme', 'connector', 'uebergreifend'].map(scope => {
        const agents = DATA.agents.filter(a => a.scope === scope);
        const color = scope === 'theme' ? 'accent' : scope === 'connector' ? 'accent-green' : 'accent-purple';
        return `
          <div class="card">
            <div class="card-header">
              <h3>${scope.charAt(0).toUpperCase() + scope.slice(1)}</h3>
              <span class="badge badge-${scope === 'theme' ? 'theme' : scope === 'connector' ? 'connector' : 'cross'}">${agents.length} Agenten</span>
            </div>
            ${agents.map(a => `
              <div style="display:flex;justify-content:space-between;padding:4px 0;font-size:0.85rem;">
                <span>${a.name}</span>
                <span class="badge badge-${a.model.split(' ')[0]}">${a.model.split(' ')[0]}</span>
              </div>
            `).join('')}
          </div>
        `;
      }).join('')}
    </div>
  `;
}

/* ── Agents ───────────────────────────────────────────── */

function renderAgents() {
  const el = document.getElementById('agents');
  const scopes = ['theme', 'connector', 'uebergreifend'];

  el.innerHTML = scopes.map(scope => {
    const agents = DATA.agents.filter(a => a.scope === scope);
    return `
      <h2 class="section-header">${scope.charAt(0).toUpperCase() + scope.slice(1)}</h2>
      <div class="cards">
        ${agents.map(a => `
          <div class="card">
            <div class="card-header">
              <h3>${a.name}</h3>
              <span class="badge badge-${a.model.split(' ')[0]}">${a.model.split(' ')[0]}</span>
              ${a.readOnly ? '<span class="badge badge-readonly">read-only</span>' : ''}
            </div>
            <div class="card-role">${a.role}</div>
            <div style="font-size:0.8rem;color:var(--text-muted);margin-bottom:8px;">
              <strong>Trigger:</strong> ${a.trigger}
            </div>
            <div style="font-size:0.8rem;color:var(--text-muted);margin-bottom:8px;">
              <strong>Phase:</strong> ${a.phase} &middot; <strong>Max Turns:</strong> ${a.maxTurns}
            </div>
            <div class="card-meta">
              ${a.writes.length ? a.writes.map(w => `<span>schreibt: ${w}</span>`).join('') : '<span>kein Schreibzugriff</span>'}
              ${a.reads.map(r => `<span>liest: ${r}</span>`).join('')}
            </div>
          </div>
        `).join('')}
      </div>
    `;
  }).join('');
}

/* ── Workflows ────────────────────────────────────────── */

function renderWorkflows() {
  const el = document.getElementById('workflows');

  el.innerHTML = Object.entries(DATA.workflows).map(([key, wf]) => `
    <div class="workflow-container">
      <div class="workflow-title">${wf.name}</div>
      <div class="workflow">
        ${wf.steps.map((step, i) => {
          let nodeClass = 'wf-node';
          if (step.phase === 'gate') nodeClass += ' gate';
          else if (step.phase === 'review') nodeClass += ' review';
          else if (step.agent) nodeClass += ' agent';
          else nodeClass += ' manual';

          return `
            ${i > 0 ? '<div class="wf-arrow">&#8594;</div>' : ''}
            <div class="wf-step">
              <div class="${nodeClass}">
                ${step.name}
                ${step.agent ? `<div class="wf-agent-name">${step.agent}</div>` : ''}
              </div>
              ${step.phase === 'review' ? '<div class="wf-revision">max 3x Revision</div>' : ''}
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `).join('');
}

/* ── Skills ───────────────────────────────────────────── */

function renderSkills() {
  const el = document.getElementById('skills');

  el.innerHTML = `
    <h2 class="section-header">Wann welchen Skill nutzen</h2>
    ${DATA.skills.map(s => `
      <div class="skill-card">
        <h3>${s.name}</h3>
        <span class="badge badge-${s.scope === 'theme' ? 'theme' : s.scope === 'connector' ? 'connector' : 'cross'}">${s.scope}</span>
        <div class="description">${s.description}</div>
        <div style="font-size:0.82rem;margin-bottom:8px;">
          <strong>Trigger:</strong> ${s.trigger}
        </div>
        ${s.phases ? `
          <div style="font-size:0.75rem;color:var(--text-muted);margin-bottom:8px;">Phasen:</div>
          <div class="skill-phases">
            ${s.phases.map((p, i) => `<span>${i + 1}. ${p}</span>`).join('')}
          </div>
        ` : ''}
        <div style="margin-top:8px;">
          <div style="font-size:0.75rem;color:var(--text-muted);">Dateien:</div>
          <div class="card-meta" style="margin-top:4px;">
            ${s.files.map(f => `<span>${f}</span>`).join('')}
          </div>
        </div>
      </div>
    `).join('')}

    <h2 class="section-header">Entscheidungsbaum: Welchen Agenten starten?</h2>
    <div class="arch-diagram">
      <svg class="arch-svg" viewBox="0 0 820 520" style="max-width:820px;">
        <defs>
          <marker id="dt-arrow" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
            <polygon points="0 0, 8 3, 0 6" fill="#58a6ff"/>
          </marker>
          <marker id="dt-arrow-green" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
            <polygon points="0 0, 8 3, 0 6" fill="#3fb950"/>
          </marker>
          <marker id="dt-arrow-muted" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
            <polygon points="0 0, 8 3, 0 6" fill="#8b949e"/>
          </marker>
        </defs>

        <!-- Start -->
        <rect x="310" y="10" width="200" height="40" rx="20" fill="#58a6ff22" stroke="#58a6ff" stroke-width="2"/>
        <text x="410" y="35" text-anchor="middle" fill="#58a6ff" font-size="13" font-weight="600">Neue Aufgabe</text>

        <!-- Decision: Figma? -->
        <polygon points="410,80 500,120 410,160 320,120" fill="#d2992222" stroke="#d29922" stroke-width="1.5"/>
        <text x="410" y="124" text-anchor="middle" fill="#d29922" font-size="11" font-weight="500">Figma-URL?</text>
        <line x1="410" y1="50" x2="410" y2="80" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-muted)"/>

        <!-- Yes: figma-extractor -->
        <rect x="540" y="100" width="150" height="36" rx="6" fill="#f778ba22" stroke="#f778ba" stroke-width="1.5"/>
        <text x="615" y="123" text-anchor="middle" fill="#f778ba" font-size="11" font-weight="600">figma-extractor</text>
        <line x1="500" y1="120" x2="540" y2="118" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-muted)"/>
        <text x="516" y="112" fill="#3fb950" font-size="9">ja</text>

        <!-- No: Decision Scope -->
        <text x="404" y="175" fill="#f85149" font-size="9">nein</text>
        <polygon points="410,185 510,225 410,265 310,225" fill="#d2992222" stroke="#d29922" stroke-width="1.5"/>
        <text x="410" y="229" text-anchor="middle" fill="#d29922" font-size="11" font-weight="500">Theme oder Connector?</text>
        <line x1="410" y1="160" x2="410" y2="185" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-muted)"/>

        <!-- Theme Branch -->
        <text x="245" y="218" fill="#58a6ff" font-size="9">Theme</text>
        <rect x="100" y="280" width="150" height="36" rx="6" fill="#58a6ff22" stroke="#58a6ff" stroke-width="1.5"/>
        <text x="175" y="303" text-anchor="middle" fill="#58a6ff" font-size="11" font-weight="600">theme-planner</text>
        <line x1="310" y1="225" x2="250" y2="290" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow)"/>

        <rect x="100" y="340" width="150" height="36" rx="6" fill="#58a6ff22" stroke="#58a6ff" stroke-width="1.5"/>
        <text x="175" y="363" text-anchor="middle" fill="#58a6ff" font-size="11" font-weight="600">liquid-implementer</text>
        <line x1="175" y1="316" x2="175" y2="340" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow)"/>
        <text x="185" y="332" fill="#8b949e" font-size="8">Freigabe</text>

        <rect x="60" y="405" width="110" height="32" rx="6" fill="#bc8cff22" stroke="#bc8cff" stroke-width="1.5"/>
        <text x="115" y="425" text-anchor="middle" fill="#bc8cff" font-size="10" font-weight="600">theme-reviewer</text>
        <rect x="185" y="405" width="110" height="32" rx="6" fill="#f8514922" stroke="#f85149" stroke-width="1.5"/>
        <text x="240" y="425" text-anchor="middle" fill="#f85149" font-size="10" font-weight="600">security-reviewer</text>
        <line x1="155" y1="376" x2="115" y2="405" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-muted)"/>
        <line x1="195" y1="376" x2="240" y2="405" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-muted)"/>
        <text x="175" y="395" text-anchor="middle" fill="#8b949e" font-size="8">parallel</text>

        <!-- Connector Branch -->
        <text x="515" y="218" fill="#3fb950" font-size="9">Connector</text>
        <rect x="560" y="280" width="150" height="36" rx="6" fill="#3fb95022" stroke="#3fb950" stroke-width="1.5"/>
        <text x="635" y="303" text-anchor="middle" fill="#3fb950" font-size="11" font-weight="600">rails-planner</text>
        <line x1="510" y1="225" x2="560" y2="290" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-green)"/>

        <rect x="560" y="340" width="150" height="36" rx="6" fill="#3fb95022" stroke="#3fb950" stroke-width="1.5"/>
        <text x="635" y="363" text-anchor="middle" fill="#3fb950" font-size="11" font-weight="600">rails-implementer</text>
        <line x1="635" y1="316" x2="635" y2="340" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-green)"/>
        <text x="645" y="332" fill="#8b949e" font-size="8">Freigabe</text>

        <rect x="530" y="405" width="100" height="32" rx="6" fill="#bc8cff22" stroke="#bc8cff" stroke-width="1.5"/>
        <text x="580" y="425" text-anchor="middle" fill="#bc8cff" font-size="10" font-weight="600">rails-reviewer</text>
        <rect x="645" y="405" width="110" height="32" rx="6" fill="#f8514922" stroke="#f85149" stroke-width="1.5"/>
        <text x="700" y="425" text-anchor="middle" fill="#f85149" font-size="10" font-weight="600">security-reviewer</text>
        <line x1="615" y1="376" x2="580" y2="405" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-muted)"/>
        <line x1="655" y1="376" x2="700" y2="405" stroke="#30363d" stroke-width="1.5" marker-end="url(#dt-arrow-muted)"/>
        <text x="635" y="395" text-anchor="middle" fill="#8b949e" font-size="8">parallel</text>

        <!-- Converge: docs-writer -->
        <rect x="330" y="470" width="160" height="36" rx="6" fill="#8b949e22" stroke="#8b949e" stroke-width="1.5"/>
        <text x="410" y="493" text-anchor="middle" fill="#8b949e" font-size="11" font-weight="600">docs-writer</text>
        <line x1="175" y1="437" x2="340" y2="480" stroke="#30363d" stroke-width="1" stroke-dasharray="4"/>
        <line x1="635" y1="437" x2="480" y2="480" stroke="#30363d" stroke-width="1" stroke-dasharray="4"/>
        <text x="410" y="462" text-anchor="middle" fill="#8b949e" font-size="8">APPROVED</text>
      </svg>
    </div>
  `;
}

/* ── Architecture ─────────────────────────────────────── */

function renderArchitecture() {
  const el = document.getElementById('architecture');

  // Boxes positioned for clear separation — no overlapping arrows
  const boxes = [
    { id: 'figma',      x: 40,  y: 40,  w: 130, h: 55, label: 'Figma',             color: '#f778ba' },
    { id: 'theme',      x: 250, y: 40,  w: 150, h: 55, label: 'Theme (Liquid)',     color: '#58a6ff' },
    { id: 'store',      x: 500, y: 40,  w: 160, h: 55, label: 'Shopify Store',      color: '#58a6ff' },
    { id: 'extensions', x: 250, y: 170, w: 150, h: 55, label: 'Extensions (5)',     color: '#bc8cff' },
    { id: 'connector',  x: 500, y: 170, w: 160, h: 55, label: 'Connector (Rails)',  color: '#3fb950' },
    { id: 'sap',        x: 500, y: 300, w: 160, h: 55, label: 'SAP',               color: '#d29922' },
    { id: 'datalayer',  x: 40,  y: 170, w: 130, h: 55, label: 'Datalayer',          color: '#8b949e' },
    { id: 'gtm',        x: 40,  y: 300, w: 130, h: 55, label: 'GTM',               color: '#8b949e' }
  ];

  function boxById(id) { return boxes.find(b => b.id === id); }
  function edge(fromId, toId, side) {
    const f = boxById(fromId), t = boxById(toId);
    // side: 'right'=right edge, 'left'=left edge, 'bottom'=bottom, 'top'=top
    const pts = {
      right:  (b) => ({ x: b.x + b.w, y: b.y + b.h / 2 }),
      left:   (b) => ({ x: b.x,       y: b.y + b.h / 2 }),
      bottom: (b) => ({ x: b.x + b.w / 2, y: b.y + b.h }),
      top:    (b) => ({ x: b.x + b.w / 2, y: b.y }),
    };
    return { f: pts[side.split('-')[0]](f), t: pts[side.split('-')[1]](t) };
  }

  // Each arrow explicitly positioned to avoid overlap
  const arrowData = [
    { from: 'figma', to: 'theme', label: 'Design', sides: 'right-left' },
    { from: 'theme', to: 'store', label: 'Theme Push', sides: 'right-left' },
    { from: 'store', to: 'connector', label: 'Webhooks', sides: 'bottom-top', offset: -20 },
    { from: 'connector', to: 'store', label: 'Admin API', sides: 'top-bottom', offset: 20 },
    { from: 'connector', to: 'sap', label: 'Order Sync', sides: 'bottom-top', offset: -20 },
    { from: 'sap', to: 'connector', label: 'Produkte', sides: 'top-bottom', offset: 20 },
    { from: 'extensions', to: 'connector', label: 'App Proxy', sides: 'right-left' },
    { from: 'extensions', to: 'store', label: 'Checkout UI', sides: 'right-left', offsetY: -15 },
    { from: 'datalayer', to: 'gtm', label: 'Events', sides: 'bottom-top' }
  ];

  const svgBoxes = boxes.map(b => `
    <rect x="${b.x}" y="${b.y}" width="${b.w}" height="${b.h}" rx="8"
      fill="${b.color}22" stroke="${b.color}" stroke-width="2"/>
    <text x="${b.x + b.w/2}" y="${b.y + b.h/2 + 5}" text-anchor="middle"
      fill="${b.color}" font-size="13" font-weight="600">${b.label}</text>
  `).join('');

  const svgArrows = arrowData.map(a => {
    const e = edge(a.from, a.to, a.sides);
    const ox = a.offset || 0;
    const oy = a.offsetY || 0;
    const x1 = e.f.x + ox, y1 = e.f.y + oy;
    const x2 = e.t.x + ox, y2 = e.t.y + oy;
    const mx = (x1 + x2) / 2, my = (y1 + y2) / 2;
    // Place label offset from line to avoid overlap
    const isVert = Math.abs(x2 - x1) < Math.abs(y2 - y1);
    const lx = isVert ? mx + (ox < 0 ? -45 : ox > 0 ? 45 : -45) : mx;
    const ly = isVert ? my : my - 8;
    return `
      <line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"
        stroke="#30363d" stroke-width="1.5" marker-end="url(#arrow)"/>
      <text x="${lx}" y="${ly}" text-anchor="middle"
        fill="#8b949e" font-size="10">${a.label}</text>
    `;
  }).join('');

  el.innerHTML = `
    <h2 class="section-header">System-Architektur</h2>
    <div class="arch-diagram">
      <svg class="arch-svg" viewBox="0 0 720 380">
        <defs>
          <marker id="arrow" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
            <polygon points="0 0, 8 3, 0 6" fill="#30363d"/>
          </marker>
        </defs>
        ${svgArrows}
        ${svgBoxes}
      </svg>
    </div>

    <h2 class="section-header">Shopify Extensions</h2>
    <div class="table-container">
      <table>
        <thead><tr><th>Extension</th><th>Typ</th><th>Zweck</th></tr></thead>
        <tbody>
          ${DATA.architecture.extensions.map(e => `
            <tr><td><strong>${e.name}</strong></td><td>${e.type}</td><td>${e.purpose}</td></tr>
          `).join('')}
        </tbody>
      </table>
    </div>

    <h2 class="section-header">Datenfluesse</h2>
    <div class="table-container">
      <table>
        <thead><tr><th>Von</th><th>Nach</th><th>Daten</th><th>Via</th></tr></thead>
        <tbody>
          ${DATA.architecture.dataFlows.map(f => `
            <tr><td>${f.from}</td><td>${f.to}</td><td>${f.label}</td><td><code>${f.via}</code></td></tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

/* ── Rules & Hooks ────────────────────────────────────── */

function renderRulesHooks() {
  const el = document.getElementById('rules');

  el.innerHTML = `
    <h2 class="section-header">Rules (pfad-scoped)</h2>
    <div class="table-container">
      <table>
        <thead><tr><th>Rule</th><th>Scope</th><th>Kernregeln</th></tr></thead>
        <tbody>
          ${DATA.rules.map(r => `
            <tr>
              <td><strong>${r.name}</strong></td>
              <td><code>${r.scope}</code></td>
              <td>${r.key_rules.join(', ')}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>

    <h2 class="section-header">Hooks</h2>
    <div class="cards">
      ${DATA.hooks.map(h => `
        <div class="card">
          <div class="card-header">
            <h3>${h.name}</h3>
            <span class="badge badge-theme">${h.event}</span>
          </div>
          ${h.blocks ? `
            <div style="font-size:0.82rem;color:var(--text-muted);">Blockiert:</div>
            <div class="card-meta" style="margin-top:6px;">
              ${h.blocks.map(b => `<span>${b}</span>`).join('')}
            </div>
          ` : `
            <div class="card-role">${h.action}</div>
          `}
        </div>
      `).join('')}
    </div>

    <h2 class="section-header">Permissions (settings.json)</h2>
    <div class="workflow-container">
      <div style="font-size:0.82rem;line-height:2;">
        <div><strong>Auto-Allow:</strong></div>
        <div style="padding-left:16px;">Theme Check, Theme Info, Theme List (in theme/)</div>
        <div style="padding-left:16px;">git status, git diff, git log</div>
        <div style="padding-left:16px;">RuboCop, Brakeman (in connector/)</div>
        <div style="padding-left:16px;">Shopify Dev MCP Tools</div>
        <div style="margin-top:8px;"><strong>Deny:</strong></div>
        <div style="padding-left:16px;color:var(--accent-red);">Edit/Write auf theme/config/settings_data.json</div>
      </div>
    </div>
  `;
}

/* ── Improvements ─────────────────────────────────────── */

function renderImprovements() {
  const el = document.getElementById('improvements');
  const items = DATA.improvements || [];

  el.innerHTML = `
    <h2 class="section-header">Verbesserungsvorschlaege</h2>
    <p style="color:var(--text-muted);font-size:0.85rem;margin-bottom:20px;">
      Priorisiert nach Risiko und Aufwand. Erledigte Items werden entfernt.
    </p>
    ${items.map(item => `
      <div class="improvement">
        <h4>${item.title}</h4>
        <p>${item.desc}</p>
        <span class="priority priority-${item.priority}">${item.priority}</span>
      </div>
    `).join('')}
  `;
}

document.addEventListener('DOMContentLoaded', init);
