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
  ['profile', 'rep', 'docs', 'status'].forEach((s) => {
    const nav = document.getElementById(`step-nav-${s}`);
    const panel = document.getElementById(`step-panel-${s}`);
    if (nav) nav.classList.toggle('active', s === step);
    if (panel) panel.style.display = s === step ? 'block' : 'none';
  });
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

  const banner = document.getElementById('global-status-banner');
  if (status === 'additional_info_required') {
    banner.className = 'alert-banner alert-warning';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Action Required: Administrator Requested Additional Information</h4>
        <p>${escapeHtml(currentCompany.additional_info_request || 'Please review your application and provide the requested corrections before resubmitting.')}</p>
      </div>`;
  } else if (status === 'rejected') {
    banner.className = 'alert-banner alert-danger';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Application Rejected by Administrator</h4>
        <p><strong>Reason:</strong> ${escapeHtml(currentCompany.rejection_reason || 'Compliance criteria not met.')}</p>
      </div>`;
  } else if (status === 'approved') {
    banner.className = 'alert-banner alert-success';
    banner.style.display = 'flex';
    banner.innerHTML = `
      <div class="alert-content">
        <h4>Congratulations! Your Company Onboarding Application is Approved</h4>
        <p>Your organization is now verified on the Dirsha platform. You can now prepare and manage IPO offering drafts.</p>
      </div>`;
  } else {
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

// ── Initialization ───────────────────────────────────────────────────────────

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-logout').addEventListener('click', handleLogout);
  initPortal();
});
