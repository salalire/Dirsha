import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import { Errors } from '../../lib/errors.js';
import { documentStorage } from './document-storage.js';

export interface BrokerDraftInput {
  broker_type?: 'individual' | 'firm';
  legal_name: string;
  trade_name?: string;
  registration_number?: string;
  tin?: string;
  business_address?: string;
  city?: string;
  country?: string;
  business_email?: string;
  business_phone?: string;
  website?: string;
  license_number: string;
  license_category: string;
  licensing_authority?: string;
  license_issued_date?: string;
  license_expiry_date: string;
  representative_name?: string;
  representative_email?: string;
  representative_phone?: string;
  representative_title?: string;
  authority_declaration?: boolean;
}

export async function saveBrokerDraft(
  db: Db,
  user: AuthUser,
  input: BrokerDraftInput,
) {

  if (user.role !== 'broker' && user.role !== 'admin') {
    throw Errors.forbidden('Only brokers can manage broker registration');
  }

  const existingRes = await db.query(
    'SELECT * FROM brokers WHERE owner_user_id = $1',
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
      `UPDATE brokers SET
        broker_type = COALESCE($1, broker_type),
        legal_name = COALESCE($2, legal_name),
        trade_name = COALESCE($3, trade_name),
        registration_number = COALESCE($4, registration_number),
        tin = COALESCE($5, tin),
        business_address = COALESCE($6, business_address),
        city = COALESCE($7, city),
        country = COALESCE($8, country),
        business_email = COALESCE($9, business_email),
        business_phone = COALESCE($10, business_phone),
        website = COALESCE($11, website),
        license_number = COALESCE($12, license_number),
        license_category = COALESCE($13, license_category),
        licensing_authority = COALESCE($14, licensing_authority),
        license_issued_date = COALESCE($15, license_issued_date),
        license_expiry_date = COALESCE($16, license_expiry_date),
        representative_name = COALESCE($17, representative_name),
        representative_email = COALESCE($18, representative_email),
        representative_phone = COALESCE($19, representative_phone),
        representative_title = COALESCE($20, representative_title),
        authority_declaration = COALESCE($21, authority_declaration)
      WHERE id = $22
      RETURNING *`,
      [
        input.broker_type ?? 'firm',
        input.legal_name,
        input.trade_name ?? null,
        input.registration_number ?? null,
        input.tin ?? null,
        input.business_address ?? null,
        input.city ?? 'Addis Ababa',
        input.country ?? 'Ethiopia',
        input.business_email ?? null,
        input.business_phone ?? null,
        input.website ?? null,
        input.license_number,
        input.license_category,
        input.licensing_authority ?? 'Ethiopian Capital Market Authority (ECMA)',
        input.license_issued_date ? new Date(input.license_issued_date) : null,
        new Date(input.license_expiry_date),
        input.representative_name ?? null,
        input.representative_email ?? null,
        input.representative_phone ?? null,
        input.representative_title ?? null,
        input.authority_declaration ?? false,
        existing.id,
      ],
    );
    return updateRes.rows[0];
  }

  const insertRes = await db.query(
    `INSERT INTO brokers (
      owner_user_id, broker_type, legal_name, trade_name, registration_number,
      tin, business_address, city, country, business_email, business_phone,
      website, license_number, license_category, licensing_authority,
      license_issued_date, license_expiry_date, representative_name,
      representative_email, representative_phone, representative_title,
      authority_declaration, onboarding_status
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
      $16, $17, $18, $19, $20, $21, $22, 'draft'
    ) RETURNING *`,
    [
      user.id,
      input.broker_type ?? 'firm',
      input.legal_name,
      input.trade_name ?? null,
      input.registration_number ?? null,
      input.tin ?? null,
      input.business_address ?? null,
      input.city ?? 'Addis Ababa',
      input.country ?? 'Ethiopia',
      input.business_email ?? null,
      input.business_phone ?? null,
      input.website ?? null,
      input.license_number,
      input.license_category,
      input.licensing_authority ?? 'Ethiopian Capital Market Authority (ECMA)',
      input.license_issued_date ? new Date(input.license_issued_date) : null,
      new Date(input.license_expiry_date),
      input.representative_name ?? null,
      input.representative_email ?? null,
      input.representative_phone ?? null,
      input.representative_title ?? null,
      input.authority_declaration ?? false,
    ],
  );

  return insertRes.rows[0];
}

export async function getBrokerApplication(db: Db, user: AuthUser) {
  const brokerRes = await db.query(
    'SELECT * FROM brokers WHERE owner_user_id = $1',
    [user.id],
  );
  const broker = brokerRes.rows[0];
  if (!broker) return null;

  const docsRes = await db.query(
    `SELECT id, document_type, file_name, file_size_bytes, mime_type, review_status, review_notes, created_at
     FROM supporting_documents
     WHERE entity_type = 'broker' AND entity_id = $1
     ORDER BY created_at ASC`,
    [broker.id],
  );

  const historyRes = await db.query(
    `SELECT h.id, h.from_status, h.to_status, h.notes, h.created_at, u.full_name AS changed_by_name
     FROM application_status_history h
     LEFT JOIN users u ON u.id = h.changed_by
     WHERE h.entity_type = 'broker' AND h.entity_id = $1
     ORDER BY h.created_at DESC`,
    [broker.id],
  );

  return {
    ...broker,
    documents: docsRes.rows,
    status_history: historyRes.rows,
  };
}

export async function submitBrokerApplication(db: Db, user: AuthUser) {
  const brokerRes = await db.query(
    'SELECT * FROM brokers WHERE owner_user_id = $1',
    [user.id],
  );
  const broker = brokerRes.rows[0];
  if (!broker) {
    throw Errors.notFound('Broker profile not found. Please complete draft first.');
  }

  if (
    broker.onboarding_status !== 'draft' &&
    broker.onboarding_status !== 'additional_info_required'
  ) {
    throw Errors.conflict(
      `Cannot submit application in status '${broker.onboarding_status}'`,
    );
  }

  // Validate required fields
  const missing: string[] = [];
  if (!broker.legal_name) missing.push('legal_name');
  if (!broker.business_address) missing.push('business_address');
  if (!broker.business_email) missing.push('business_email');
  if (!broker.business_phone) missing.push('business_phone');
  if (!broker.license_number) missing.push('license_number');
  if (!broker.license_category) missing.push('license_category');
  if (!broker.license_expiry_date) missing.push('license_expiry_date');
  if (!broker.authority_declaration) missing.push('authority_declaration');

  if (missing.length > 0) {
    throw Errors.validation({ missing_fields: missing }, 'Required broker fields are missing');
  }

  // Check expiry date
  const expiry = new Date(broker.license_expiry_date);
  if (expiry.getTime() < Date.now()) {
    throw Errors.validation(
      { field: 'license_expiry_date', expiry: broker.license_expiry_date },
      'Broker license has expired. Valid license is required for submission.',
    );
  }

  // Mandatory document: broker_license
  const docsRes = await db.query(
    `SELECT document_type FROM supporting_documents
     WHERE entity_type = 'broker' AND entity_id = $1`,
    [broker.id],
  );
  const types = new Set(docsRes.rows.map((r) => r.document_type));
  if (!types.has('broker_license')) {
    throw Errors.validation(
      { missing_document: 'broker_license' },
      'Broker License Document is required before submission',
    );
  }

  const nextStatus = broker.onboarding_status === 'additional_info_required' ? 'resubmitted' : 'submitted';

  return await db.tx(async (client) => {
    const updateRes = await client.query(
      `UPDATE brokers SET
        onboarding_status = $1,
        additional_info_request = NULL,
        updated_at = now()
       WHERE id = $2 RETURNING *`,
      [nextStatus, broker.id],
    );

    await client.query(
      `UPDATE users SET verification_status = 'pending' WHERE id = $1`,
      [user.id],
    );

    await client.query(
      `INSERT INTO application_status_history (
        entity_type, entity_id, from_status, to_status, changed_by, notes
      ) VALUES ('broker', $1, $2, $3, $4, 'Application submitted by broker')`,
      [broker.id, broker.onboarding_status, nextStatus, user.id],
    );

    return updateRes.rows[0];
  });
}

export async function uploadBrokerDocument(
  db: Db,
  user: AuthUser,
  doc: {
    document_type: string;
    file_name: string;
    mime_type: string;
    content: string; // base64
  },
) {
  const brokerRes = await db.query(
    'SELECT id, onboarding_status FROM brokers WHERE owner_user_id = $1',
    [user.id],
  );
  const broker = brokerRes.rows[0];
  if (!broker) {
    throw Errors.notFound('Broker profile not found. Please create draft first.');
  }

  if (
    broker.onboarding_status !== 'draft' &&
    broker.onboarding_status !== 'additional_info_required'
  ) {
    throw Errors.conflict(
      `Documents cannot be added or replaced in status '${broker.onboarding_status}'`,
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
    ) VALUES ($1, 'broker', $2, $3, $4, $5, $6, $7, 'pending')
    RETURNING id, document_type, file_name, file_size_bytes, mime_type, review_status, created_at`,
    [
      user.id,
      broker.id,
      doc.document_type,
      stored.fileName,
      stored.fileSizeBytes,
      stored.mimeType,
      stored.storageKey,
    ],
  );

  return insertRes.rows[0];
}

export async function getBrokerDocumentFile(db: Db, user: AuthUser, docId: string) {
  const docRes = await db.query(
    'SELECT * FROM supporting_documents WHERE id = $1 AND entity_type = \'broker\'',
    [docId],
  );
  const doc = docRes.rows[0];
  if (!doc) throw Errors.notFound('Document not found');

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

export async function deleteBrokerDocument(db: Db, user: AuthUser, docId: string) {
  const docRes = await db.query(
    'SELECT * FROM supporting_documents WHERE id = $1 AND entity_type = \'broker\'',
    [docId],
  );
  const doc = docRes.rows[0];
  if (!doc) throw Errors.notFound('Document not found');

  if (doc.owner_user_id !== user.id && user.role !== 'admin') {
    throw Errors.forbidden('You do not have permission to delete this document');
  }

  const brokerRes = await db.query(
    'SELECT onboarding_status FROM brokers WHERE id = $1',
    [doc.entity_id],
  );
  const broker = brokerRes.rows[0];
  if (
    broker &&
    broker.onboarding_status !== 'draft' &&
    broker.onboarding_status !== 'additional_info_required'
  ) {
    throw Errors.conflict(`Cannot delete documents in status '${broker.onboarding_status}'`);
  }

  await db.query('DELETE FROM supporting_documents WHERE id = $1', [docId]);
  await documentStorage.deleteFile(doc.storage_key);
  return { deleted: true, id: docId };
}


