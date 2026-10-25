// Dirsha Company Onboarding Web Portal Client Logic

const API_BASE = window.location.origin;
let authToken = localStorage.getItem('dirsha_company_token') || sessionStorage.getItem('dirsha_company_token');
let currentCompany = null;
let currentDocuments = [];
let currentStep = 'profile';

// ── Toast Utility ────────────────────────────────────────────────────────────

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

// ── Auth Handling ────────────────────────────────────────────────────────────

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

    if (json.data.user.role !== 'company_rep' && json.data.user.role !== 'admin') {
      throw new Error('Only company representatives can access this onboarding portal');
    }

    authToken = json.data.access_token;
    localStorage.setItem('dirsha_company_token', authToken);
    localStorage.setItem('dirsha_company_email', json.data.user.email);
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
        role: 'company_rep',
      }),
    });
    const regJson = await regRes.json();
    if (!regRes.ok) throw new Error(regJson.error?.message || 'Registration failed');

    // Automatically sign in
    const loginRes = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const loginJson = await loginRes.json();
    authToken = loginJson.data.access_token;
    localStorage.setItem('dirsha_company_token', authToken);
    localStorage.setItem('dirsha_company_email', email);
    showToast('Account created and signed in');
    initPortal();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

function handleLogout() {
  authToken = null;
  currentCompany = null;
  localStorage.removeItem('dirsha_company_token');
  localStorage.removeItem('dirsha_company_email');
  document.getElementById('auth-header-section').style.display = 'none';
  document.getElementById('auth-section').style.display = 'block';
  document.getElementById('workflow-section').style.display = 'none';
  showToast('Signed out');
}

// ── Stepper Navigation ───────────────────────────────────────────────────────

function goToStep(step) {
  currentStep = step;
  ['profile', 'rep', 'docs', 'status', 'offerings'].forEach((s) => {
    const nav = document.getElementById(`step-nav-${s}`);
    const panel = document.getElementById(`step-panel-${s}`);
    if (nav) nav.classList.toggle('active', s === step);
    if (panel) panel.style.display = s === step ? 'block' : 'none';
  });
  if (step === 'offerings') {
    loadOfferings();
  }
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ── Application State & API ──────────────────────────────────────────────────

async function fetchCompanyApplication() {
  if (!authToken) return null;
  const res = await fetch(`${API_BASE}/onboarding/company`, {
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

  const email = localStorage.getItem('dirsha_company_email') || 'Representative';
  document.getElementById('user-display-email').innerText = email;
  document.getElementById('auth-header-section').style.display = 'flex';
  document.getElementById('auth-section').style.display = 'none';
  document.getElementById('workflow-section').style.display = 'block';

  currentCompany = await fetchCompanyApplication();
  renderCompanyData();
  setupDropzoneAndFileInput();
}

function renderCompanyData() {
  if (!currentCompany) {
    goToStep('profile');
    renderChecklist();
    return;
  }

  // Populate profile fields
  document.getElementById('company-legal-name').value = currentCompany.legal_name || '';
  document.getElementById('company-trade-name').value = currentCompany.trade_name || '';
  document.getElementById('company-reg-number').value = currentCompany.registration_number || '';
  document.getElementById('company-entity-type').value = currentCompany.legal_entity_type || 'plc';
  document.getElementById('company-country').value = currentCompany.country_of_incorporation || 'Ethiopia';
  document.getElementById('company-inc-date').value = currentCompany.incorporation_date ? currentCompany.incorporation_date.substring(0, 10) : '';
  document.getElementById('company-tin').value = currentCompany.tin || '';
  document.getElementById('company-vat').value = currentCompany.vat_number || '';
  document.getElementById('company-industry').value = currentCompany.industry_sector || '';
  document.getElementById('company-website').value = currentCompany.website || '';
  document.getElementById('company-business-address').value = currentCompany.business_address || '';
  document.getElementById('company-operating-address').value = currentCompany.operating_address || '';
  document.getElementById('company-business-email').value = currentCompany.business_email || '';
  document.getElementById('company-business-phone').value = currentCompany.business_phone || '';
  document.getElementById('company-description').value = currentCompany.description || '';

  // Populate rep fields
  document.getElementById('rep-name').value = currentCompany.representative_name || '';
  document.getElementById('rep-title').value = currentCompany.representative_title || '';
  document.getElementById('rep-email').value = currentCompany.representative_email || '';
  document.getElementById('rep-phone').value = currentCompany.representative_phone || '';
  document.getElementById('rep-role-desc').value = currentCompany.representative_role_description || '';
  document.getElementById('rep-declaration').checked = Boolean(currentCompany.authority_declaration);

  // Documents
  currentDocuments = currentCompany.documents || [];
  renderDocumentsList();

  // Status & Lock controls
  renderStatusView();
  renderChecklist();
  renderTimeline();
}

function renderStatusView() {
  const status = currentCompany ? currentCompany.onboarding_status : 'draft';
  const badgeHtml = `<span class="status-pill status-${status}"><span class="dot"></span> ${status.replace(/_/g, ' ')}</span>`;
  document.getElementById('profile-status-badge').innerHTML = badgeHtml;
  document.getElementById('final-status-badge').innerHTML = badgeHtml;

  const navOfferings = document.getElementById('step-nav-offerings');

  const banner = document.getElementById('global-status-banner');
  if (status === 'additional_info_required') {
    if (navOfferings) navOfferings.style.display = 'none';
    banner.className = 'alert-banner alert-warning';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Action Required: Administrator Requested Additional Information</h4>
        <p>${escapeHtml(currentCompany.additional_info_request || 'Please review your application and provide the requested corrections before resubmitting.')}</p>
      </div>`;
  } else if (status === 'rejected') {
    if (navOfferings) navOfferings.style.display = 'none';
    banner.className = 'alert-banner alert-danger';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Application Rejected by Administrator</h4>
        <p><strong>Reason:</strong> ${escapeHtml(currentCompany.rejection_reason || 'Compliance criteria not met.')}</p>
      </div>`;
  } else if (status === 'approved') {
    if (navOfferings) navOfferings.style.display = 'flex';
    banner.className = 'alert-banner alert-success';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content" style="flex: 1;">
        <h4>Congratulations! Your Company Onboarding Application is Approved</h4>
        <p>Your organization is fully verified on the Dirsha platform. You can now create and manage IPO offerings.</p>
        <div style="margin-top: 12px;">
          <button class="btn btn-primary" type="button" onclick="goToStep('offerings')">Open IPO Issuer Dashboard &rarr;</button>
        </div>
      </div>`;
  } else {
    if (navOfferings) navOfferings.style.display = 'none';
    banner.style.display = 'none';
  }

  // Lock forms if submitted, under review, approved
  const isEditable = status === 'draft' || status === 'additional_info_required';
  setFormEditable(isEditable);
}

function setFormEditable(editable) {
  const inputs = document.querySelectorAll('#workflow-section input, #workflow-section select, #workflow-section textarea');
  inputs.forEach((inp) => {
    inp.disabled = !editable;
  });
  const saveButtons = document.querySelectorAll('#btn-save-profile, #btn-save-rep, #btn-upload-doc');
  saveButtons.forEach((btn) => {
    btn.style.display = editable ? 'inline-flex' : 'none';
  });

  const submitBox = document.getElementById('submission-action-box');
  const btnSubmit = document.getElementById('btn-submit-app');
  if (currentCompany && (currentCompany.onboarding_status === 'submitted' || currentCompany.onboarding_status === 'resubmitted' || currentCompany.onboarding_status === 'under_review')) {
    submitBox.innerHTML = `
      <h3 style="font-size: 18px; font-weight: 700; margin-bottom: 8px;">Application Under Review</h3>
      <p style="color: var(--text-secondary); font-size: 14px;">Your application has been received and is being processed by the Dirsha compliance team. You will be notified here if additional information is required.</p>
    `;
  } else if (currentCompany && currentCompany.onboarding_status === 'approved') {
    submitBox.innerHTML = `
      <h3 style="font-size: 18px; font-weight: 700; color: var(--primary); margin-bottom: 8px;">Approved &amp; Active</h3>
      <p style="color: var(--text-secondary); font-size: 14px;">This company registration is approved.</p>
    `;
  } else if (currentCompany && currentCompany.onboarding_status === 'additional_info_required') {
    btnSubmit.innerText = 'Resubmit Application with Corrections';
    btnSubmit.disabled = false;
  }
}

function renderChecklist() {
  const checklist = document.getElementById('checklist-items');
  if (!checklist) return;

  const items = [
    { label: 'Registered Legal Name & Reg Number', done: Boolean(currentCompany?.legal_name && currentCompany?.registration_number) },
    { label: 'Tax Identification Number (TIN)', done: Boolean(currentCompany?.tin) },
    { label: 'Registered Head Office Address', done: Boolean(currentCompany?.business_address) },
    { label: 'Corporate Contact Email & Phone', done: Boolean(currentCompany?.business_email && currentCompany?.business_phone) },
    { label: 'Authorized Representative Appointed', done: Boolean(currentCompany?.representative_name && currentCompany?.representative_email) },
    { label: 'Authority Declaration Confirmed', done: Boolean(currentCompany?.authority_declaration) },
    { label: 'Commercial Registration Certificate Uploaded', done: currentDocuments.some((d) => d.document_type === 'commercial_registration') },
    { label: 'TIN Certificate Uploaded', done: currentDocuments.some((d) => d.document_type === 'tin_certificate') },
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
  if (btnSubmit && currentCompany && (currentCompany.onboarding_status === 'draft' || currentCompany.onboarding_status === 'additional_info_required')) {
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

  const isEditable = !currentCompany || currentCompany.onboarding_status === 'draft' || currentCompany.onboarding_status === 'additional_info_required';

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

  const history = currentCompany?.status_history || [];
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

// ── Save Form Handlers ───────────────────────────────────────────────────────

async function handleSaveProfile(e) {
  e.preventDefault();
  const btn = document.getElementById('btn-save-profile');
  btn.disabled = true;

  const payload = {
    legal_name: document.getElementById('company-legal-name').value.trim(),
    trade_name: document.getElementById('company-trade-name').value.trim() || undefined,
    registration_number: document.getElementById('company-reg-number').value.trim(),
    legal_entity_type: document.getElementById('company-entity-type').value,
    country_of_incorporation: document.getElementById('company-country').value.trim() || 'Ethiopia',
    incorporation_date: document.getElementById('company-inc-date').value || undefined,
    tin: document.getElementById('company-tin').value.trim() || undefined,
    vat_number: document.getElementById('company-vat').value.trim() || undefined,
    industry_sector: document.getElementById('company-industry').value.trim() || undefined,
    website: document.getElementById('company-website').value.trim() || undefined,
    business_address: document.getElementById('company-business-address').value.trim() || undefined,
    operating_address: document.getElementById('company-operating-address').value.trim() || undefined,
    business_email: document.getElementById('company-business-email').value.trim() || undefined,
    business_phone: document.getElementById('company-business-phone').value.trim() || undefined,
    description: document.getElementById('company-description').value.trim() || undefined,
  };

  try {
    const res = await fetch(`${API_BASE}/onboarding/company/draft`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to save profile');

    currentCompany = await fetchCompanyApplication();
    showToast('Company details saved');
    renderCompanyData();
    goToStep('rep');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

async function handleSaveRep(e) {
  e.preventDefault();
  const btn = document.getElementById('btn-save-rep');
  btn.disabled = true;

  const payload = {
    legal_name: document.getElementById('company-legal-name').value.trim(),
    registration_number: document.getElementById('company-reg-number').value.trim(),
    representative_name: document.getElementById('rep-name').value.trim(),
    representative_title: document.getElementById('rep-title').value.trim(),
    representative_email: document.getElementById('rep-email').value.trim(),
    representative_phone: document.getElementById('rep-phone').value.trim(),
    representative_role_description: document.getElementById('rep-role-desc').value.trim() || undefined,
    authority_declaration: document.getElementById('rep-declaration').checked,
  };

  try {
    const res = await fetch(`${API_BASE}/onboarding/company/draft`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to save representative details');

    currentCompany = await fetchCompanyApplication();
    showToast('Representative details saved');
    renderCompanyData();
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

      const res = await fetch(`${API_BASE}/onboarding/company/documents`, {
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

    showToast(files.length > 1 ? `${files.length} documents uploaded successfully` : 'Document uploaded successfully');
    fileInput.value = '';
    updateSelectedFilesPreview();

    currentCompany = await fetchCompanyApplication();
    renderCompanyData();

    // Auto-advance dropdown to next missing mandatory document if applicable
    const uploadedTypes = new Set((currentCompany?.documents || []).map((d) => d.document_type));
    if (uploadedTypes.has('commercial_registration') && !uploadedTypes.has('tin_certificate')) {
      typeSelect.value = 'tin_certificate';
    } else if (uploadedTypes.has('tin_certificate') && !uploadedTypes.has('memorandum_of_association')) {
      typeSelect.value = 'memorandum_of_association';
    }
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerText = 'Upload Selected Document(s)';
  }
}

async function handleDeleteDoc(docId) {
  if (!confirm('Are you sure you want to remove this document?')) return;
  try {
    const res = await fetch(`${API_BASE}/onboarding/company/documents/${docId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) {
      const json = await res.json();
      throw new Error(json.error?.message || 'Delete failed');
    }
    showToast('Document removed');
    currentCompany = await fetchCompanyApplication();
    renderCompanyData();
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

// ── Submit Application ───────────────────────────────────────────────────────

async function handleSubmitApplication() {
  const btn = document.getElementById('btn-submit-app');
  btn.disabled = true;
  btn.innerText = 'Submitting...';

  try {
    const res = await fetch(`${API_BASE}/onboarding/company/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({}),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Submission failed');

    showToast('Application submitted successfully!');
    currentCompany = await fetchCompanyApplication();
    renderCompanyData();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerText = 'Submit Application';
  }
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) modal.style.display = 'none';
}

// ── IPO Offerings Lifecycle Management (Decision 2) ─────────────────────────

let currentOfferings = [];

async function loadOfferings() {
  if (!authToken) return;
  const listEl = document.getElementById('offerings-list');
  if (!listEl) return;
  listEl.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">Loading offerings...</p>';

  try {
    const res = await fetch(`${API_BASE}/ipos/my-offerings`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) {
      const errJson = await res.json().catch(() => ({}));
      throw new Error(errJson.error?.message || 'Failed to load offerings');
    }
    const json = await res.json();
    currentOfferings = json.data || [];
    renderOfferings();
  } catch (err) {
    listEl.innerHTML = `<p style="color: var(--danger); font-size: 13px;">Error: ${escapeHtml(err.message)}</p>`;
  }
}

function renderOfferings() {
  const listEl = document.getElementById('offerings-list');
  if (!listEl) return;

  // Compute KPIs
  const total = currentOfferings.length;
  const inReview = currentOfferings.filter((o) => o.status === 'submitted' || o.status === 'under_review').length;
  const active = currentOfferings.filter((o) => o.status === 'approved' || o.status === 'open').length;
  const totalSubs = currentOfferings.reduce((sum, o) => sum + (o.subscription_count || 0), 0);

  document.getElementById('kpi-total-offerings').innerText = total;
  document.getElementById('kpi-review-offerings').innerText = inReview;
  document.getElementById('kpi-active-offerings').innerText = active;
  document.getElementById('kpi-total-subscriptions').innerText = totalSubs;

  if (currentOfferings.length === 0) {
    listEl.innerHTML = `
      <div style="text-align: center; padding: 48px 24px; border: 1px dashed var(--border); border-radius: var(--radius-md); background: var(--bg-surface);">
        <h4 style="font-size: 16px; font-weight: 700; margin-bottom: 8px;">No IPO Offerings Created Yet</h4>
        <p style="color: var(--text-secondary); font-size: 14px; max-width: 480px; margin: 0 auto 16px;">
          Your company is approved. Start your primary market issuance by creating a new IPO draft.
        </p>
        <button class="btn btn-primary" type="button" onclick="openCreateIpoModal()">+ Create New IPO Draft</button>
      </div>`;
    return;
  }

  listEl.innerHTML = currentOfferings
    .map((offering) => {
      const priceEtb = (offering.price_per_share_minor / 100).toFixed(2);
      const opensStr = offering.opens_at ? new Date(offering.opens_at).toLocaleString() : '—';
      const closesStr = offering.closes_at ? new Date(offering.closes_at).toLocaleString() : '—';
      const isDraft = offering.status === 'draft';
      const hasFeedback = offering.rejection_reason || offering.review_notes;

      let feedbackHtml = '';
      if (offering.rejection_reason) {
        feedbackHtml = `
          <div class="offering-feedback-box">
            <strong>Administrator Feedback / Rejection Reason:</strong> ${escapeHtml(offering.rejection_reason)}
          </div>`;
      } else if (offering.review_notes) {
        feedbackHtml = `
          <div class="offering-notes-box">
            <strong>Administrator Review Notes:</strong> ${escapeHtml(offering.review_notes)}
          </div>`;
      }

      return `
        <div class="offering-card">
          <div class="offering-header-row">
            <div class="offering-title-group">
              <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                <span class="offering-symbol-badge">${escapeHtml(offering.symbol)}</span>
                <h3>${escapeHtml(offering.title)}</h3>
              </div>
              <p style="font-size: 13px; color: var(--text-muted); margin-top: 4px;">
                ${escapeHtml(offering.description || 'No description provided.')}
              </p>
            </div>
            <div>
              <span class="status-pill status-${offering.status}">
                <span class="dot"></span> ${offering.status.replace(/_/g, ' ')}
              </span>
            </div>
          </div>

          <div class="offering-meta-grid">
            <div class="meta-item">
              <span class="meta-label">Share Price</span>
              <span class="meta-value">${priceEtb} ETB</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Total Shares</span>
              <span class="meta-value">${Number(offering.total_shares).toLocaleString()}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Min Subscription</span>
              <span class="meta-value">${Number(offering.min_shares_per_subscription || 1).toLocaleString()} shares</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Subscriptions</span>
              <span class="meta-value">${offering.subscription_count || 0} (${Number(offering.total_shares_subscribed || 0).toLocaleString()} shares)</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Opening</span>
              <span class="meta-value" style="font-size: 12px;">${opensStr}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Closing</span>
              <span class="meta-value" style="font-size: 12px;">${closesStr}</span>
            </div>
          </div>

          ${feedbackHtml}

          <div class="offering-actions">
            ${isDraft ? `
              <button class="btn btn-primary" type="button" onclick="handleSubmitIpoForReview('${offering.id}', '${escapeHtml(offering.title)}')">
                Submit for Compliance Review &rarr;
              </button>
              <button class="btn btn-secondary" type="button" onclick="openCreateIpoModal('${offering.id}')">
                Edit Offering Details
              </button>
            ` : ''}
            <button class="btn btn-secondary" type="button" onclick="openIpoDocsModal('${offering.id}', '${escapeHtml(offering.title)}')">
              Offering Documents (${offering.documents_count || (offering.documents ? offering.documents.length : 0)})
            </button>
            <button class="btn btn-secondary" type="button" onclick="openIpoHistoryModal('${offering.id}', '${escapeHtml(offering.title)}')">
              Review History & Audit
            </button>
          </div>
        </div>
      `;
    })
    .join('');
}

function openCreateIpoModal(ipoId) {
  const modal = document.getElementById('modal-ipo-form');
  const titleEl = document.getElementById('modal-ipo-title');
  const idInput = document.getElementById('ipo-draft-id');

  if (ipoId) {
    const item = currentOfferings.find((o) => o.id === ipoId);
    if (!item) return;
    titleEl.innerText = 'Edit IPO Offering Draft';
    idInput.value = item.id;
    document.getElementById('ipo-title').value = item.title;
    document.getElementById('ipo-symbol').value = item.symbol;
    document.getElementById('ipo-price').value = (item.price_per_share_minor / 100).toFixed(2);
    document.getElementById('ipo-total-shares').value = item.total_shares;
    document.getElementById('ipo-min-shares').value = item.min_shares_per_subscription || 1;
    document.getElementById('ipo-max-shares').value = item.max_shares_per_subscription || '';
    document.getElementById('ipo-opens-at').value = item.opens_at ? item.opens_at.slice(0, 16) : '';
    document.getElementById('ipo-closes-at').value = item.closes_at ? item.closes_at.slice(0, 16) : '';
    document.getElementById('ipo-description').value = item.description || '';
  } else {
    titleEl.innerText = 'Create IPO Offering Draft';
    idInput.value = '';
    document.getElementById('form-ipo-draft').reset();
    document.getElementById('ipo-min-shares').value = '1';

    // Set default dates: opens tomorrow, closes in 14 days
    const now = new Date();
    const opens = new Date(now.getTime() + 86400000);
    const closes = new Date(now.getTime() + 86400000 * 14);
    document.getElementById('ipo-opens-at').value = opens.toISOString().slice(0, 16);
    document.getElementById('ipo-closes-at').value = closes.toISOString().slice(0, 16);
  }

  modal.style.display = 'flex';
}

async function handleSaveIpoDraft(event) {
  event.preventDefault();
  const idInput = document.getElementById('ipo-draft-id').value;
  const isEdit = Boolean(idInput);
  const btn = document.getElementById('btn-save-ipo');
  btn.disabled = true;
  btn.innerText = 'Saving...';

  const title = document.getElementById('ipo-title').value.trim();
  const symbol = document.getElementById('ipo-symbol').value.trim().toUpperCase();
  const price = parseFloat(document.getElementById('ipo-price').value);
  const totalShares = parseInt(document.getElementById('ipo-total-shares').value, 10);
  const minShares = parseInt(document.getElementById('ipo-min-shares').value, 10) || 1;
  const maxSharesVal = document.getElementById('ipo-max-shares').value;
  const maxShares = maxSharesVal ? parseInt(maxSharesVal, 10) : null;
  const opensAt = document.getElementById('ipo-opens-at').value;
  const closesAt = document.getElementById('ipo-closes-at').value;
  const description = document.getElementById('ipo-description').value.trim() || null;

  if (new Date(closesAt) <= new Date(opensAt)) {
    showToast('Closing date must be strictly after opening date', 'error');
    btn.disabled = false;
    btn.innerText = 'Save Offering Draft';
    return;
  }

  const payload = {
    title,
    symbol,
    price_per_share_minor: Math.round(price * 100),
    total_shares: totalShares,
    min_shares_per_subscription: minShares,
    max_shares_per_subscription: maxShares,
    opens_at: new Date(opensAt).toISOString(),
    closes_at: new Date(closesAt).toISOString(),
    description,
  };

  try {
    const url = isEdit ? `${API_BASE}/ipos/${idInput}` : `${API_BASE}/ipos`;
    const method = isEdit ? 'PUT' : 'POST';

    const res = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify(payload),
    });

    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to save offering');

    showToast(isEdit ? 'IPO offering draft updated!' : 'IPO offering draft created!');
    closeModal('modal-ipo-form');
    await loadOfferings();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerText = 'Save Offering Draft';
  }
}

async function handleSubmitIpoForReview(ipoId, ipoTitle) {
  const confirmed = confirm(`Submit offering "${ipoTitle}" for formal compliance review? Once submitted, the draft cannot be edited until reviewed.`);
  if (!confirmed) return;

  const notes = prompt('Enter submission notes for the review team (optional):') || undefined;

  try {
    const res = await fetch(`${API_BASE}/ipos/${ipoId}/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({ notes }),
    });

    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Submission failed');

    showToast('Offering submitted for regulatory review!');
    await loadOfferings();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function openIpoDocsModal(ipoId, ipoTitle) {
  document.getElementById('current-doc-ipo-id').value = ipoId;
  document.getElementById('modal-ipo-docs-title').innerText = `Documents: ${ipoTitle}`;
  const modal = document.getElementById('modal-ipo-docs');
  modal.style.display = 'flex';
  await loadIpoDocuments(ipoId);
}

async function loadIpoDocuments(ipoId) {
  const listEl = document.getElementById('ipo-uploaded-docs-list');
  listEl.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">Loading documents...</p>';

  try {
    const res = await fetch(`${API_BASE}/ipos/${ipoId}/documents`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) throw new Error('Failed to load documents');
    const json = await res.json();
    const docs = json.data || [];

    if (docs.length === 0) {
      listEl.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">No documents uploaded yet.</p>';
      return;
    }

    listEl.innerHTML = docs
      .map(
        (doc) => `
        <div class="doc-item">
          <div class="doc-icon">&#128196;</div>
          <div class="doc-details">
            <span class="doc-name">${escapeHtml(doc.file_name)}</span>
            <span class="doc-meta">
              ${escapeHtml(doc.document_type.replace(/_/g, ' '))} &bull;
              ${(doc.file_size_bytes / 1024).toFixed(1)} KB &bull;
              Status: ${escapeHtml(doc.review_status)}
            </span>
          </div>
          <div class="doc-actions">
            <button class="btn-doc-action" type="button" onclick="downloadIpoDoc('${ipoId}', '${doc.id}', '${escapeHtml(doc.file_name)}')">Download</button>
            <button class="btn-doc-action btn-danger-action" type="button" onclick="handleDeleteIpoDoc('${ipoId}', '${doc.id}')">Delete</button>
          </div>
        </div>
      `,
      )
      .join('');
  } catch (err) {
    listEl.innerHTML = `<p style="color: var(--danger); font-size: 13px;">Error: ${escapeHtml(err.message)}</p>`;
  }
}

async function handleUploadIpoDocument() {
  const ipoId = document.getElementById('current-doc-ipo-id').value;
  const fileInput = document.getElementById('ipo-doc-file-input');
  const typeSelect = document.getElementById('ipo-doc-type-select');
  const btn = document.getElementById('btn-upload-ipo-doc');

  if (!fileInput.files || fileInput.files.length === 0) {
    showToast('Please select a file to upload', 'error');
    return;
  }

  const file = fileInput.files[0];
  if (file.size > 10 * 1024 * 1024) {
    showToast('File size must not exceed 10MB', 'error');
    return;
  }

  btn.disabled = true;
  btn.innerText = 'Uploading...';

  try {
    const base64 = await fileToBase64(file);
    const res = await fetch(`${API_BASE}/ipos/${ipoId}/documents`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        document_type: typeSelect.value,
        file_name: file.name,
        mime_type: file.type || 'application/pdf',
        content: base64,
      }),
    });

    const json = await res.json();
    if (!res.ok) throw new Error(json.error?.message || 'Failed to upload document');

    showToast('Document uploaded successfully!');
    fileInput.value = '';
    await loadIpoDocuments(ipoId);
    await loadOfferings();
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerText = 'Upload Document';
  }
}

async function handleDeleteIpoDoc(ipoId, docId) {
  if (!confirm('Are you sure you want to delete this document?')) return;

  try {
    const res = await fetch(`${API_BASE}/ipos/${ipoId}/documents/${docId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      throw new Error(json.error?.message || 'Failed to delete document');
    }
    showToast('Document removed');
    await loadIpoDocuments(ipoId);
    await loadOfferings();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function downloadIpoDoc(ipoId, docId, fileName) {
  try {
    const res = await fetch(`${API_BASE}/ipos/${ipoId}/documents/${docId}/file`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) throw new Error('Download failed');
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function openIpoHistoryModal(ipoId, ipoTitle) {
  document.getElementById('modal-history-ipo-title').innerText = `Review Trail: ${ipoTitle}`;
  const modal = document.getElementById('modal-ipo-history');
  const timelineEl = document.getElementById('ipo-history-timeline');
  timelineEl.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">Loading history...</p>';
  modal.style.display = 'flex';

  try {
    const res = await fetch(`${API_BASE}/ipos/${ipoId}/history`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) throw new Error('Failed to load review history');
    const json = await res.json();
    const history = json.data || [];

    if (history.length === 0) {
      timelineEl.innerHTML = '<p style="color: var(--text-muted); font-size: 13px;">No history records yet.</p>';
      return;
    }

    timelineEl.innerHTML = history
      .map(
        (item) => `
        <div class="timeline-item">
          <div class="timeline-time">${new Date(item.created_at).toLocaleString()}</div>
          <div class="timeline-body">
            <strong>Transition:</strong> ${item.from_status ? item.from_status.replace(/_/g, ' ') : 'initial'} &rarr; <span class="status-pill status-${item.to_status}">${item.to_status.replace(/_/g, ' ')}</span>
            ${item.reason ? `<div style="margin-top: 4px; color: var(--text-secondary); font-size: 13px;"><strong>Notes:</strong> ${escapeHtml(item.reason)}</div>` : ''}
          </div>
        </div>
      `,
      )
      .join('');
  } catch (err) {
    timelineEl.innerHTML = `<p style="color: var(--danger); font-size: 13px;">Error: ${escapeHtml(err.message)}</p>`;
  }
}

// ── Initialization ───────────────────────────────────────────────────────────

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-logout').addEventListener('click', handleLogout);
  initPortal();
});
