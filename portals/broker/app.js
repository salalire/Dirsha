// Dirsha Broker Onboarding Web Portal Client Logic

const API_BASE = window.location.origin;
let authToken = localStorage.getItem('dirsha_broker_token') || sessionStorage.getItem('dirsha_broker_token');
let currentBroker = null;
let currentDocuments = [];
let currentStep = 'profile';

function showToast(message, type = 'success') {
  const container = document.getElementById('toast-container');
  if (!container) return;
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerText = message;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

function switchAuthTab(tab) {
  const loginTab = document.getElementById('tab-login');
  const registerTab = document.getElementById('tab-register');
  const loginForm = document.getElementById('form-login');
  const registerForm = document.getElementById('form-register');

  if (tab === 'login') {
    loginTab.classList.add('active');
    registerTab.classList.remove('active');
    loginForm.style.display = 'block';
    registerForm.style.display = 'none';
  } else {
    loginTab.classList.remove('active');
    registerTab.classList.add('active');
    loginForm.style.display = 'none';
    registerForm.style.display = 'block';
  }
}

async function handleLogin(e) {
  e.preventDefault();
  const email = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;
  const btn = document.getElementById('btn-submit-login');
  btn.disabled = true;

  try {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Sign in failed');

    if (json.data.user.role !== 'broker' && json.data.user.role !== 'admin') {
      throw new Error('Only broker applicants can access this onboarding portal');
    }

    authToken = json.data.access_token;
    localStorage.setItem('dirsha_broker_token', authToken);
    localStorage.setItem('dirsha_broker_email', json.data.user.email);
    showToast('Signed in successfully');
    initPortal();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

async function handleRegister(e) {
  e.preventDefault();
  const fullName = document.getElementById('reg-fullname').value.trim();
  const email = document.getElementById('reg-email').value.trim();
  const phone = document.getElementById('reg-phone').value.trim();
  const password = document.getElementById('reg-password').value;
  const btn = document.getElementById('btn-submit-register');
  btn.disabled = true;

  try {
    const regRes = await fetch(`${API_BASE}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        full_name: fullName,
        phone: phone || undefined,
        role: 'broker',
      }),
    });
    const regJson = await regRes.json();
    if (!regRes.ok) throw new Error(regJson.error?.message || 'Registration failed');

    const loginRes = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const loginJson = await loginRes.json();
    authToken = loginJson.data.access_token;
    localStorage.setItem('dirsha_broker_token', authToken);
    localStorage.setItem('dirsha_broker_email', email);
    showToast('Broker account created and signed in');
    initPortal();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

function handleLogout() {
  authToken = null;
  currentBroker = null;
  localStorage.removeItem('dirsha_broker_token');
  localStorage.removeItem('dirsha_broker_email');
  document.getElementById('auth-header-section').style.display = 'none';
  document.getElementById('auth-section').style.display = 'block';
  document.getElementById('workflow-section').style.display = 'none';
  showToast('Signed out');
}

function goToStep(step) {
  currentStep = step;
  ['profile', 'license', 'docs', 'status', 'clients'].forEach((s) => {
    const nav = document.getElementById(`step-nav-${s}`);
    const panel = document.getElementById(`step-panel-${s}`);
    if (nav) nav.classList.toggle('active', s === step);
    if (panel) panel.style.display = s === step ? 'block' : 'none';
  });
  if (step === 'clients') {
    loadBrokerDashboard();
    loadBrokerClients();
  }
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

async function fetchBrokerApplication() {
  if (!authToken) return null;
  const res = await fetch(`${API_BASE}/onboarding/broker`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  if (res.status === 401) {
    handleLogout();
    return null;
  }
  const json = await res.json();
  return json.data;
}

async function initPortal() {
  if (!authToken) {
    document.getElementById('auth-section').style.display = 'block';
    document.getElementById('workflow-section').style.display = 'none';
    document.getElementById('auth-header-section').style.display = 'none';
    return;
  }

  const email = localStorage.getItem('dirsha_broker_email') || 'Broker Applicant';
  document.getElementById('user-display-email').innerText = email;
  document.getElementById('auth-header-section').style.display = 'flex';
  document.getElementById('auth-section').style.display = 'none';
  document.getElementById('workflow-section').style.display = 'block';

  currentBroker = await fetchBrokerApplication();
  renderBrokerData();
  setupDropzoneAndFileInput();
}

function renderBrokerData() {
  if (!currentBroker) {
    goToStep('profile');
    renderChecklist();
    return;
  }

  document.getElementById('broker-type').value = currentBroker.broker_type || 'firm';
  document.getElementById('broker-legal-name').value = currentBroker.legal_name || '';
  document.getElementById('broker-trade-name').value = currentBroker.trade_name || '';
  document.getElementById('broker-reg-number').value = currentBroker.registration_number || '';
  document.getElementById('broker-tin').value = currentBroker.tin || '';
  document.getElementById('broker-city').value = currentBroker.city || 'Addis Ababa';
  document.getElementById('broker-business-address').value = currentBroker.business_address || '';
  document.getElementById('broker-business-email').value = currentBroker.business_email || '';
  document.getElementById('broker-business-phone').value = currentBroker.business_phone || '';
  document.getElementById('broker-website').value = currentBroker.website || '';

  // License
  document.getElementById('broker-license-number').value = currentBroker.license_number || '';
  document.getElementById('broker-license-category').value = currentBroker.license_category || 'securities_broker';
  document.getElementById('broker-authority').value = currentBroker.licensing_authority || 'Ethiopian Capital Market Authority (ECMA)';
  document.getElementById('broker-issued-date').value = currentBroker.license_issued_date ? currentBroker.license_issued_date.substring(0, 10) : '';
  document.getElementById('broker-expiry-date').value = currentBroker.license_expiry_date ? currentBroker.license_expiry_date.substring(0, 10) : '';
  document.getElementById('broker-rep-name').value = currentBroker.representative_name || '';
  document.getElementById('broker-declaration').checked = Boolean(currentBroker.authority_declaration);

  currentDocuments = currentBroker.documents || [];
  renderDocumentsList();

  renderStatusView();
  renderChecklist();
  renderTimeline();
}

function renderStatusView() {
  const status = currentBroker ? currentBroker.onboarding_status : 'draft';
  const badgeHtml = `<span class="status-pill status-${status}"><span class="dot"></span> ${status.replace(/_/g, ' ')}</span>`;
  document.getElementById('profile-status-badge').innerHTML = badgeHtml;
  document.getElementById('final-status-badge').innerHTML = badgeHtml;

  const banner = document.getElementById('global-status-banner');
  if (status === 'additional_info_required') {
    banner.className = 'alert-banner alert-warning';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Action Required: Administrator Requested Additional Information</h4>
        <p>${escapeHtml(currentBroker.additional_info_request || 'Please review your application and provide the requested corrections before resubmitting.')}</p>
      </div>`;
  } else if (status === 'rejected') {
    banner.className = 'alert-banner alert-danger';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Broker Application Rejected by Administrator</h4>
        <p><strong>Reason:</strong> ${escapeHtml(currentBroker.rejection_reason || 'Compliance criteria not met.')}</p>
      </div>`;
  } else if (status === 'approved') {
    const clientsNav = document.getElementById('step-nav-clients');
    if (clientsNav) clientsNav.style.display = 'flex';

    banner.className = 'alert-banner alert-success';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Broker License Approved by Platform Administrator</h4>
        <p>Your brokerage credentials have been verified and activated on the platform.</p>
        <button class="btn btn-primary" style="margin-top: 12px; font-size: 13px;" onclick="goToStep('clients')">
          Open Broker Operations &amp; Clients Dashboard &rarr;
        </button>
      </div>`;
  } else {
    banner.style.display = 'none';
  }

  const isEditable = status === 'draft' || status === 'additional_info_required';
  setFormEditable(isEditable);
}

function setFormEditable(editable) {
  const inputs = document.querySelectorAll('#workflow-section input, #workflow-section select, #workflow-section textarea');
  inputs.forEach((inp) => {
    inp.disabled = !editable;
  });
  const saveButtons = document.querySelectorAll('#btn-save-profile, #btn-save-license, #btn-upload-doc');
  saveButtons.forEach((btn) => {
    btn.style.display = editable ? 'inline-flex' : 'none';
  });

  const submitBox = document.getElementById('submission-action-box');
  const btnSubmit = document.getElementById('btn-submit-app');
  if (currentBroker && (currentBroker.onboarding_status === 'submitted' || currentBroker.onboarding_status === 'resubmitted' || currentBroker.onboarding_status === 'under_review')) {
    submitBox.innerHTML = `
      <h3 style="font-size: 18px; font-weight: 700; margin-bottom: 8px;">Broker Application Under Review</h3>
      <p style="color: var(--text-secondary); font-size: 14px;">Your licensing credentials are being verified with the Ethiopian Capital Market Authority (ECMA).</p>
    `;
  } else if (currentBroker && currentBroker.onboarding_status === 'approved') {
    submitBox.innerHTML = `
      <h3 style="font-size: 18px; font-weight: 700; color: var(--primary); margin-bottom: 8px;">Approved Brokerage</h3>
      <p style="color: var(--text-secondary); font-size: 14px; margin-bottom: 16px;">Your broker account is authorized for client relationship management and secondary-market operations.</p>
      <button class="btn btn-primary" type="button" onclick="goToStep('clients')">Go to Broker Dashboard</button>
    `;
  } else if (currentBroker && currentBroker.onboarding_status === 'additional_info_required') {
    btnSubmit.innerText = 'Resubmit Broker Application';
    btnSubmit.disabled = false;
  }
}

function renderChecklist() {
  const checklist = document.getElementById('checklist-items');
  if (!checklist) return;

  const isExpiryValid = currentBroker?.license_expiry_date && new Date(currentBroker.license_expiry_date).getTime() > Date.now();

  const items = [
    { label: 'Full Legal / Firm Name Provided', done: Boolean(currentBroker?.legal_name) },
    { label: 'Office Address, City & Country', done: Boolean(currentBroker?.business_address && currentBroker?.city) },
    { label: 'Business Email & Phone Provided', done: Boolean(currentBroker?.business_email && currentBroker?.business_phone) },
    { label: 'ECMA License Number & Category', done: Boolean(currentBroker?.license_number && currentBroker?.license_category) },
    { label: 'Valid License Expiry Date (Not Expired)', done: Boolean(isExpiryValid) },
    { label: 'Authority Declaration Confirmed', done: Boolean(currentBroker?.authority_declaration) },
    { label: 'Official Broker License Document Uploaded', done: currentDocuments.some((d) => d.document_type === 'broker_license') },
  ];

  checklist.innerHTML = items
    .map(
      (it) => `
      <div style="display: flex; align-items: center; gap: 8px; color: ${it.done ? 'var(--primary)' : 'var(--text-muted)'}">
        <span>${it.done ? '&#10004;' : '&#9675;'}</span>
        <span style="color: ${it.done ? 'var(--text-primary)' : 'var(--text-secondary)'}">${it.label}</span>
      </div>`,
    )
    .join('');

  const btnSubmit = document.getElementById('btn-submit-app');
  if (btnSubmit && currentBroker && (currentBroker.onboarding_status === 'draft' || currentBroker.onboarding_status === 'additional_info_required')) {
    const allDone = items.every((i) => i.done);
    btnSubmit.disabled = !allDone;
  }
}

function renderDocumentsList() {
  const list = document.getElementById('uploaded-docs-list');
  if (!list) return;

  if (currentDocuments.length === 0) {
    list.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">No documents uploaded yet.</p>';
    return;
  }

  const isEditable = !currentBroker || currentBroker.onboarding_status === 'draft' || currentBroker.onboarding_status === 'additional_info_required';

  list.innerHTML = currentDocuments
    .map((doc) => {
      const typeLabel = doc.document_type.replace(/_/g, ' ').toUpperCase();
      const sizeKb = Math.round(doc.file_size_bytes / 1024);
      return `
        <div class="doc-item">
          <div class="doc-item-info">
            <div class="doc-icon">&#128196;</div>
            <div class="doc-details">
              <h5>${escapeHtml(doc.file_name)}</h5>
              <p>${typeLabel} &bull; ${sizeKb} KB &bull; Status: <span class="status-pill status-${doc.review_status}">${doc.review_status}</span></p>
            </div>
          </div>
          <div class="doc-actions">
            <a href="${API_BASE}/onboarding/documents/${doc.id}" target="_blank" class="btn-icon" title="View Document">&#128065;</a>
            ${isEditable ? `<button type="button" class="btn-icon delete" title="Delete Document" onclick="handleDeleteDoc('${doc.id}')">&#128465;</button>` : ''}
          </div>
        </div>
      `;
    })
    .join('');
}

function renderTimeline() {
  const container = document.getElementById('status-timeline');
  if (!container) return;

  const history = currentBroker?.status_history || [];
  if (history.length === 0) {
    container.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">No review history recorded yet.</p>';
    return;
  }

  container.innerHTML = history
    .map((h) => {
      const date = new Date(h.created_at).toLocaleString();
      return `
        <div class="timeline-item">
          <div class="timeline-dot"></div>
          <div class="timeline-header">
            <span class="timeline-title">${escapeHtml(h.to_status.replace(/_/g, ' ').toUpperCase())}</span>
            <span class="timeline-time">${date}</span>
          </div>
          ${h.notes ? `<div class="timeline-notes">${escapeHtml(h.notes)}</div>` : ''}
        </div>
      `;
    })
    .join('');
}

async function handleSaveProfile(e) {
  e.preventDefault();
  const btn = document.getElementById('btn-save-profile');
  btn.disabled = true;

  const payload = {
    broker_type: document.getElementById('broker-type').value,
    legal_name: document.getElementById('broker-legal-name').value.trim(),
    trade_name: document.getElementById('broker-trade-name').value.trim() || undefined,
    registration_number: document.getElementById('broker-reg-number').value.trim() || undefined,
    tin: document.getElementById('broker-tin').value.trim() || undefined,
    city: document.getElementById('broker-city').value.trim() || 'Addis Ababa',
    country: 'Ethiopia',
    business_address: document.getElementById('broker-business-address').value.trim() || undefined,
    business_email: document.getElementById('broker-business-email').value.trim() || undefined,
    business_phone: document.getElementById('broker-business-phone').value.trim() || undefined,
    website: document.getElementById('broker-website').value.trim() || undefined,
    license_number: document.getElementById('broker-license-number').value.trim() || 'PENDING',
    license_category: document.getElementById('broker-license-category').value || 'securities_broker',
    license_expiry_date: document.getElementById('broker-expiry-date').value || new Date(Date.now() + 365*24*3600*1000).toISOString().split('T')[0],
  };

  try {
    const res = await fetch(`${API_BASE}/onboarding/broker/draft`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to save broker profile');

    currentBroker = await fetchBrokerApplication();
    showToast('Broker profile saved');
    renderBrokerData();
    goToStep('license');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

async function handleSaveLicense(e) {
  e.preventDefault();
  const btn = document.getElementById('btn-save-license');
  btn.disabled = true;

  const expiry = document.getElementById('broker-expiry-date').value;
  if (new Date(expiry).getTime() < Date.now()) {
    showToast('License expiry date must be in the future', 'error');
    btn.disabled = false;
    return;
  }

  const payload = {
    legal_name: document.getElementById('broker-legal-name').value.trim(),
    business_address: document.getElementById('broker-business-address').value.trim(),
    business_email: document.getElementById('broker-business-email').value.trim(),
    business_phone: document.getElementById('broker-business-phone').value.trim(),
    license_number: document.getElementById('broker-license-number').value.trim(),
    license_category: document.getElementById('broker-license-category').value,
    licensing_authority: document.getElementById('broker-authority').value.trim(),
    license_issued_date: document.getElementById('broker-issued-date').value || undefined,
    license_expiry_date: expiry,
    representative_name: document.getElementById('broker-rep-name').value.trim() || undefined,
    authority_declaration: document.getElementById('broker-declaration').checked,
  };

  try {
    const res = await fetch(`${API_BASE}/onboarding/broker/draft`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to save license details');

    currentBroker = await fetchBrokerApplication();
    showToast('Licensing details saved');
    renderBrokerData();
    goToStep('docs');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

// ── Document Upload & Delete ─────────────────────────────────────────────────

function setupDropzoneAndFileInput() {
  const dropzone = document.getElementById('dropzone');
  const fileInput = document.getElementById('doc-file-input');
  if (!dropzone || !fileInput) return;

  ['dragenter', 'dragover'].forEach((eventName) => {
    dropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      dropzone.classList.add('dragover');
    }, false);
  });

  ['dragleave', 'drop'].forEach((eventName) => {
    dropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      dropzone.classList.remove('dragover');
    }, false);
  });

  dropzone.addEventListener('drop', (e) => {
    const dt = e.dataTransfer;
    if (dt && dt.files && dt.files.length > 0) {
      fileInput.files = dt.files;
      updateSelectedFilesPreview();
    }
  }, false);

  fileInput.addEventListener('change', updateSelectedFilesPreview);
}

function updateSelectedFilesPreview() {
  const fileInput = document.getElementById('doc-file-input');
  const preview = document.getElementById('selected-files-preview');
  const dropMainText = document.getElementById('dropzone-main-text');
  const dropSubText = document.getElementById('dropzone-sub-text');
  if (!fileInput || !preview) return;

  const files = Array.from(fileInput.files || []);
  if (files.length === 0) {
    preview.style.display = 'none';
    preview.innerHTML = '';
    if (dropMainText) dropMainText.innerHTML = '<strong>Click to choose file(s)</strong> or drag and drop here';
    if (dropSubText) dropSubText.innerText = 'Supported: PDF, PNG, JPG (maximum 10MB per document)';
    return;
  }

  const itemsHtml = files
    .map((f) => {
      const sizeKb = Math.round(f.size / 1024);
      return `<div style="display: flex; align-items: center; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid rgba(255,255,255,0.05);">
        <span>&#128196; <strong>${escapeHtml(f.name)}</strong> (${sizeKb} KB)</span>
        <span style="color: var(--primary); font-size: 11px;">Ready</span>
      </div>`;
    })
    .join('');

  preview.style.display = 'block';
  preview.innerHTML = `
    <div style="font-weight: 600; margin-bottom: 6px; color: var(--text-primary);">&#10004; ${files.length} file(s) selected:</div>
    ${itemsHtml}
  `;

  if (dropMainText) dropMainText.innerHTML = `<strong>${files.length} file(s) selected</strong>`;
  if (dropSubText) dropSubText.innerText = 'Click again or drag to replace selection';
}

async function handleUploadDocument() {
  const fileInput = document.getElementById('doc-file-input');
  const typeSelect = document.getElementById('doc-type-select');
  const files = Array.from(fileInput.files || []);

  if (files.length === 0) {
    showToast('Please select one or more files to upload', 'error');
    return;
  }

  for (const f of files) {
    if (f.size > 10 * 1024 * 1024) {
      showToast(`File "${f.name}" exceeds maximum allowed size of 10MB`, 'error');
      return;
    }
  }

  const btn = document.getElementById('btn-upload-doc');
  btn.disabled = true;

  try {
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      btn.innerText = files.length > 1 ? `Uploading (${i + 1}/${files.length})...` : 'Uploading...';

      const base64 = await toBase64(file);
      const payload = {
        document_type: typeSelect.value,
        file_name: file.name,
        mime_type: file.type || (file.name.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'image/png'),
        content: base64,
      };

      const res = await fetch(`${API_BASE}/onboarding/broker/documents`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authToken}`,
        },
        body: JSON.stringify(payload),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error?.message || `Upload failed for ${file.name}`);
    }

    showToast(files.length > 1 ? `${files.length} documents uploaded successfully` : 'License document uploaded');
    fileInput.value = '';
    updateSelectedFilesPreview();

    currentBroker = await fetchBrokerApplication();
    renderBrokerData();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerText = 'Upload License Document(s)';
  }
}

async function handleDeleteDoc(docId) {
  if (!confirm('Are you sure you want to remove this document?')) return;
  try {
    const res = await fetch(`${API_BASE}/onboarding/broker/documents/${docId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) {
      const json = await res.json();
      throw new Error(json.error?.message || 'Delete failed');
    }
    showToast('Document removed');
    currentBroker = await fetchBrokerApplication();
    renderBrokerData();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function toBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      const result = reader.result;
      const base64 = result.split(',')[1];
      resolve(base64);
    };
    reader.onerror = (error) => reject(error);
  });
}

async function handleSubmitApplication() {
  const btn = document.getElementById('btn-submit-app');
  btn.disabled = true;
  btn.innerText = 'Submitting...';

  try {
    const res = await fetch(`${API_BASE}/onboarding/broker/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({}),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Submission failed');

    showToast('Broker application submitted successfully!');
    currentBroker = await fetchBrokerApplication();
    renderBrokerData();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerText = 'Submit Broker Application';
  }
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ── Broker Dashboard & Client Operations ──────────────────────────────────
let brokerClients = [];

function formatSantim(minor) {
  const val = Number(minor || 0) / 100;
  return `${val.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ETB`;
}

async function loadBrokerDashboard() {
  if (!authToken) return;
  try {
    const res = await fetch(`${API_BASE}/brokers/dashboard`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to load dashboard metrics');

    const metrics = json.metrics || {};
    document.getElementById('kpi-active-clients').innerText = metrics.total_active_clients ?? 0;
    document.getElementById('kpi-pending-clients').innerText = metrics.pending_client_requests ?? 0;
    document.getElementById('kpi-available-ipos').innerText = metrics.available_ipos_count ?? 0;
    document.getElementById('kpi-assisted-orders').innerText = metrics.assisted_orders_count ?? 0;
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function loadBrokerClients() {
  if (!authToken) return;
  const statusFilter = document.getElementById('client-filter-status').value;
  const url = statusFilter ? `${API_BASE}/brokers/clients?status=${encodeURIComponent(statusFilter)}` : `${API_BASE}/brokers/clients`;

  try {
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to load client roster');

    brokerClients = json.data || [];
    renderClientsTable();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function renderClientsTable() {
  const tbody = document.getElementById('clients-table-body');
  if (!tbody) return;

  if (brokerClients.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 24px;">
          No client relationships found matching criteria.
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = brokerClients.map((c) => {
    const statusClass = c.status === 'active' ? 'status-approved' : (c.status === 'pending' ? 'status-submitted' : 'status-rejected');
    const scopeLabel = c.relationship_type.replace(/_/g, ' ').toUpperCase();
    const dateFormatted = new Date(c.requested_at).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });

    const actionBtn = c.status === 'active'
      ? `<button class="btn btn-secondary" style="font-size: 12px; padding: 6px 12px;" onclick="inspectClientPortfolio('${c.investor_id}', '${escapeHtml(c.investor_name)}')">View Portfolio</button>`
      : `<span style="color: var(--text-muted); font-size: 12px;">Awaiting consent</span>`;

    return `
      <tr>
        <td>
          <div style="font-weight: 600; color: var(--text-primary);">${escapeHtml(c.investor_name)}</div>
          <div style="font-size: 12px; color: var(--text-muted);">${escapeHtml(c.investor_email)}</div>
        </td>
        <td>
          <span style="display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; background: rgba(99, 102, 241, 0.15); color: #818cf8; border: 1px solid rgba(99, 102, 241, 0.3);">
            ${escapeHtml(scopeLabel)}
          </span>
          ${c.notes ? `<div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">${escapeHtml(c.notes)}</div>` : ''}
        </td>
        <td>
          <span class="status-pill ${statusClass}"><span class="dot"></span> ${c.status}</span>
        </td>
        <td style="color: var(--text-secondary); font-size: 12px;">
          ${dateFormatted}
        </td>
        <td>
          ${actionBtn}
        </td>
      </tr>
    `;
  }).join('');
}

async function handleRequestClient(e) {
  e.preventDefault();
  const emailInput = document.getElementById('req-investor-email');
  const typeInput = document.getElementById('req-rel-type');
  const notesInput = document.getElementById('req-notes');
  const btn = document.getElementById('btn-submit-client-req');

  const investor_email = emailInput.value.trim();
  const relationship_type = typeInput.value;
  const notes = notesInput.value.trim();

  if (!investor_email) return;

  btn.disabled = true;
  btn.innerText = 'Sending Request...';

  try {
    const res = await fetch(`${API_BASE}/brokers/clients/request`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        investor_email,
        relationship_type,
        notes: notes || undefined,
      }),
    });

    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to request relationship');

    showToast('Authorized client relationship request sent successfully');
    emailInput.value = '';
    notesInput.value = '';
    loadBrokerDashboard();
    loadBrokerClients();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerText = 'Send Relationship Request';
  }
}

async function inspectClientPortfolio(clientId, clientName) {
  if (!authToken) return;
  try {
    const res = await fetch(`${API_BASE}/brokers/clients/${clientId}`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Access denied or portfolio inspection failed');

    const data = json;
    document.getElementById('modal-portfolio-subtitle').innerText =
      `Authorized Client: ${clientName} (${data.client?.email || ''}) — ${data.relationship?.relationship_type?.toUpperCase() || ''}`;

    const wallet = data.wallet || {};
    document.getElementById('portfolio-available-cash').innerText = formatSantim(wallet.available_minor);
    document.getElementById('portfolio-reserved-cash').innerText = formatSantim(wallet.reserved_minor);
    document.getElementById('portfolio-total-cash').innerText = formatSantim(wallet.total_minor);

    const holdingsContainer = document.getElementById('portfolio-holdings-container');
    const holdings = data.holdings || [];
    if (holdings.length === 0) {
      holdingsContainer.innerHTML = `<p style="color: var(--text-muted); font-size: 13px;">No share holdings currently held in this client's simulated portfolio.</p>`;
    } else {
      holdingsContainer.innerHTML = `
        <div class="clients-table-container" style="margin-top: 8px;">
          <table class="clients-table">
            <thead>
              <tr>
                <th>Security / Company</th>
                <th>Total Shares</th>
                <th>Reserved Shares</th>
                <th>Available</th>
              </tr>
            </thead>
            <tbody>
              ${holdings.map((h) => `
                <tr>
                  <td>
                    <div style="font-weight: 600; color: var(--text-primary);">${escapeHtml(h.symbol)}</div>
                    <div style="font-size: 11px; color: var(--text-muted);">${escapeHtml(h.company_name)}</div>
                  </td>
                  <td style="font-weight: 600;">${Number(h.quantity).toLocaleString()}</td>
                  <td style="color: var(--warning);">${Number(h.reserved_quantity).toLocaleString()}</td>
                  <td style="color: var(--primary); font-weight: 600;">${(Number(h.quantity) - Number(h.reserved_quantity)).toLocaleString()}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      `;
    }

    document.getElementById('modal-client-portfolio').style.display = 'flex';
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function closePortfolioModal() {
  document.getElementById('modal-client-portfolio').style.display = 'none';
}

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-logout').addEventListener('click', handleLogout);
  initPortal();
});
