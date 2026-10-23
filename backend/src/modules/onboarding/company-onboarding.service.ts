import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import { Errors } from '../../lib/errors.js';
import { documentStorage } from './document-storage.js';

export interface CompanyDraftInput {
  legal_name: string;
  trade_name?: string;
  registration_number: string;
  legal_entity_type?: 'plc' | 'share_company' | 'sole_proprietorship' | 'partnership' | 'corporation' | 'other';
  country_of_incorporation?: string;
  incorporation_date?: string;
  business_address?: string;
  operating_address?: string;
  business_email?: string;
  business_phone?: string;
  website?: string;
  industry_sector?: string;
  description?: string;
  tin?: string;
  vat_number?: string;
  representative_name?: string;
  representative_email?: string;
  representative_phone?: string;
  representative_title?: string;
  representative_role_description?: string;
  authority_declaration?: boolean;
}

export async function saveCompanyDraft(
  db: Db,
  user: AuthUser,
  input: CompanyDraftInput,
) {
  // Must be company_rep or admin
  if (user.role !== 'company_rep' && user.role !== 'admin') {
    throw Errors.forbidden('Only company representatives can manage company onboarding');
  }

  // Check if existing company exists for this user
  const existingRes = await db.query(
    'SELECT * FROM companies WHERE owner_user_id = $1',
    [user.id],
  );
  const existing = existingRes.rows[0];

  if (existing) {
    if (
      existing.onboarding_status !== 'draft' &&
      existing.onboarding_status !== 'additional_info_required'
    ) {
      throw Errors.conflict(
        `Application cannot be edited while in status '${existing.onboarding_status}'`,
      );
    }

    const updateRes = await db.query(
      `UPDATE companies SET
        legal_name = COALESCE($1, legal_name),
        trade_name = COALESCE($2, trade_name),
        registration_number = COALESCE($3, registration_number),
        legal_entity_type = COALESCE($4, legal_entity_type),
        country_of_incorporation = COALESCE($5, country_of_incorporation),
        incorporation_date = COALESCE($6, incorporation_date),
        business_address = COALESCE($7, business_address),
        operating_address = COALESCE($8, operating_address),
        business_email = COALESCE($9, business_email),
        business_phone = COALESCE($10, business_phone),
        website = COALESCE($11, website),
        industry_sector = COALESCE($12, industry_sector),
        description = COALESCE($13, description),
        tin = COALESCE($14, tin),
        vat_number = COALESCE($15, vat_number),
        representative_name = COALESCE($16, representative_name),
        representative_email = COALESCE($17, representative_email),
        representative_phone = COALESCE($18, representative_phone),
        representative_title = COALESCE($19, representative_title),
        representative_role_description = COALESCE($20, representative_role_description),
        authority_declaration = COALESCE($21, authority_declaration)
      WHERE id = $22
      RETURNING *`,
      [
        input.legal_name,
        input.trade_name ?? null,
        input.registration_number,
        input.legal_entity_type ?? 'plc',
        input.country_of_incorporation ?? 'Ethiopia',
        input.incorporation_date ? new Date(input.incorporation_date) : null,
        input.business_address ?? null,
        input.operating_address ?? null,
        input.business_email ?? null,
        input.business_phone ?? null,
        input.website ?? null,
        input.industry_sector ?? null,
        input.description ?? null,
        input.tin ?? null,
        input.vat_number ?? null,
        input.representative_name ?? null,
        input.representative_email ?? null,
        input.representative_phone ?? null,
        input.representative_title ?? null,
        input.representative_role_description ?? null,
        input.authority_declaration ?? false,
        existing.id,
      ],
    );
    return updateRes.rows[0];
  }

  // Create new row
  const insertRes = await db.query(
    `INSERT INTO companies (
      owner_user_id, legal_name, trade_name, registration_number,
      legal_entity_type, country_of_incorporation, incorporation_date,
      business_address, operating_address, business_email, business_phone,
      website, industry_sector, description, tin, vat_number,
      representative_name, representative_email, representative_phone,
      representative_title, representative_role_description, authority_declaration,
      onboarding_status
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16,
      $17, $18, $19, $20, $21, $22, 'draft'
    ) RETURNING *`,
    [
      user.id,
      input.legal_name,
      input.trade_name ?? null,
      input.registration_number,
      input.legal_entity_type ?? 'plc',
      input.country_of_incorporation ?? 'Ethiopia',
      input.incorporation_date ? new Date(input.incorporation_date) : null,
      input.business_address ?? null,
      input.operating_address ?? null,
      input.business_email ?? null,
      input.business_phone ?? null,
      input.website ?? null,
      input.industry_sector ?? null,
      input.description ?? null,
      input.tin ?? null,
      input.vat_number ?? null,
      input.representative_name ?? null,
      input.representative_email ?? null,
      input.representative_phone ?? null,
      input.representative_title ?? null,
      input.representative_role_description ?? null,
      input.authority_declaration ?? false,
    ],
  );

  return insertRes.rows[0];
}

export async function getCompanyApplication(db: Db, user: AuthUser) {
  const companyRes = await db.query(
    'SELECT * FROM companies WHERE owner_user_id = $1',
    [user.id],
  );
  const company = companyRes.rows[0];
  if (!company) return null;

  const docsRes = await db.query(
    `SELECT id, document_type, file_name, file_size_bytes, mime_type, review_status, review_notes, created_at
     FROM supporting_documents
     WHERE entity_type = 'company' AND entity_id = $1
     ORDER BY created_at ASC`,
    [company.id],
  );

  const historyRes = await db.query(
    `SELECT h.id, h.from_status, h.to_status, h.notes, h.created_at, u.full_name AS changed_by_name
     FROM application_status_history h
     LEFT JOIN users u ON u.id = h.changed_by
     WHERE h.entity_type = 'company' AND h.entity_id = $1
     ORDER BY h.created_at DESC`,
    [company.id],
  );

  return {
    ...company,
    documents: docsRes.rows,
    status_history: historyRes.rows,
  };
}

export async function submitCompanyApplication(db: Db, user: AuthUser) {
  const companyRes = await db.query(
    'SELECT * FROM companies WHERE owner_user_id = $1',
    [user.id],
  );
  const company = companyRes.rows[0];
  if (!company) {
    throw Errors.notFound('Company profile not found. Please complete draft first.');
  }

  if (
    company.onboarding_status !== 'draft' &&
    company.onboarding_status !== 'additional_info_required'
  ) {
    throw Errors.conflict(
      `Cannot submit application in status '${company.onboarding_status}'`,
    );
  }

  // Validate required fields
  const missing: string[] = [];
  if (!company.legal_name) missing.push('legal_name');
  if (!company.registration_number) missing.push('registration_number');
  if (!company.tin) missing.push('tin');
  if (!company.business_address) missing.push('business_address');
  if (!company.business_email) missing.push('business_email');
  if (!company.business_phone) missing.push('business_phone');
  if (!company.representative_name) missing.push('representative_name');
  if (!company.representative_email) missing.push('representative_email');
  if (!company.authority_declaration) missing.push('authority_declaration');

  if (missing.length > 0) {
    throw Errors.validation({ missing_fields: missing }, 'Required company fields are missing');
  }

  // Validate mandatory documents: commercial_registration and tin_certificate
  const docsRes = await db.query(
    `SELECT document_type FROM supporting_documents
     WHERE entity_type = 'company' AND entity_id = $1`,
    [company.id],
  );
  const types = new Set(docsRes.rows.map((r) => r.document_type));
  if (!types.has('commercial_registration')) {
    throw Errors.validation(
      { missing_document: 'commercial_registration' },
      'Commercial Registration Certificate is required before submission',
    );
  }
  if (!types.has('tin_certificate')) {
    throw Errors.validation(
      { missing_document: 'tin_certificate' },
      'TIN Certificate is required before submission',
    );
  }

  const nextStatus = company.onboarding_status === 'additional_info_required' ? 'resubmitted' : 'submitted';

  return await db.tx(async (client) => {
    const updateRes = await client.query(
      `UPDATE companies SET
        onboarding_status = $1,
        additional_info_request = NULL,
        updated_at = now()
       WHERE id = $2 RETURNING *`,
      [nextStatus, company.id],
    );

    // Update user's verification status to pending
    await client.query(
      `UPDATE users SET verification_status = 'pending' WHERE id = $1`,
      [user.id],
    );

    // Record history
    await client.query(
      `INSERT INTO application_status_history (
        entity_type, entity_id, from_status, to_status, changed_by, notes
      ) VALUES ('company', $1, $2, $3, $4, 'Application submitted by representative')`,
      [company.id, company.onboarding_status, nextStatus, user.id],
    );

    return updateRes.rows[0];
  });
}

export async function uploadCompanyDocument(
  db: Db,
  user: AuthUser,
  doc: {
    document_type: string;
    file_name: string;
    mime_type: string;
    content: string; // base64
  },
) {
  const companyRes = await db.query(
    'SELECT id, onboarding_status FROM companies WHERE owner_user_id = $1',
    [user.id],
  );
  const company = companyRes.rows[0];
  if (!company) {
    throw Errors.notFound('Company profile not found. Please create draft first.');
  }

  if (
    company.onboarding_status !== 'draft' &&
    company.onboarding_status !== 'additional_info_required'
  ) {
    throw Errors.conflict(
      `Documents cannot be added or replaced in status '${company.onboarding_status}'`,
    );
  }

  const stored = await documentStorage.saveFile({
    fileName: doc.file_name,
    mimeType: doc.mime_type,
    content: doc.content,
  });

  const insertRes = await db.query(
    `INSERT INTO supporting_documents (
      owner_user_id, entity_type, entity_id, document_type,
      file_name, file_size_bytes, mime_type, storage_key, review_status
    ) VALUES ($1, 'company', $2, $3, $4, $5, $6, $7, 'pending')
    RETURNING id, document_type, file_name, file_size_bytes, mime_type, review_status, created_at`,
    [
      user.id,
      company.id,
      doc.document_type,
      stored.fileName,
      stored.fileSizeBytes,
      stored.mimeType,
      stored.storageKey,
    ],
  );

  return insertRes.rows[0];
}

export async function getCompanyDocumentFile(db: Db, user: AuthUser, docId: string) {
  const docRes = await db.query(
    'SELECT * FROM supporting_documents WHERE id = $1 AND entity_type = \'company\'',
    [docId],
  );
  const doc = docRes.rows[0];
  if (!doc) throw Errors.notFound('Document not found');

  // Must be owner or admin
  if (doc.owner_user_id !== user.id && user.role !== 'admin') {
    throw Errors.forbidden('You do not have permission to view this document');
  }

  const buffer = await documentStorage.readFile(doc.storage_key);
  return {
    buffer,
    mimeType: doc.mime_type,
    fileName: doc.file_name,
  };
}

export async function deleteCompanyDocument(db: Db, user: AuthUser, docId: string) {

  const docRes = await db.query(
    'SELECT * FROM supporting_documents WHERE id = $1 AND entity_type = \'company\'',
    [docId],
  );
  const doc = docRes.rows[0];
  if (!doc) throw Errors.notFound('Document not found');

  if (doc.owner_user_id !== user.id && user.role !== 'admin') {
    throw Errors.forbidden('You do not have permission to delete this document');
  }

  const companyRes = await db.query(
    'SELECT onboarding_status FROM companies WHERE id = $1',
    [doc.entity_id],
  );
  const company = companyRes.rows[0];
  if (
    company &&
    company.onboarding_status !== 'draft' &&
    company.onboarding_status !== 'additional_info_required'
  ) {
    throw Errors.conflict(`Cannot delete documents in status '${company.onboarding_status}'`);
  }

  await db.query('DELETE FROM supporting_documents WHERE id = $1', [docId]);
  await documentStorage.deleteFile(doc.storage_key);
  return { deleted: true, id: docId };
}

