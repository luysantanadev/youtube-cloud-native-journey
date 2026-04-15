'use strict'

// Popula a tabela com os dados retornados por /api/env e atualiza o footer.
async function loadEnvData() {
  const response = await fetch('/api/env')
  const { vars, nodeVersion } = await response.json()

  const tbody = document.getElementById('env-table-body')
  tbody.innerHTML = ''

  for (const { label, value, source } of vars) {
    const tr = document.createElement('tr')

    const tdName = document.createElement('td')
    tdName.className = 'var-name'
    const code = document.createElement('code')
    code.textContent = label
    tdName.appendChild(code)

    const tdValue = document.createElement('td')
    tdValue.className = 'var-value'
    tdValue.textContent = value

    const tdSource = document.createElement('td')
    tdSource.className = 'var-source'
    tdSource.textContent = source

    tr.append(tdName, tdValue, tdSource)
    tbody.appendChild(tr)
  }

  const nodeVersionEl = document.getElementById('node-version')
  if (nodeVersionEl) nodeVersionEl.textContent = nodeVersion
}

// Carga inicial + atualização periódica para refletir o uptime em tempo real.
loadEnvData()
setInterval(loadEnvData, 5000)
