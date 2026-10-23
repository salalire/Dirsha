import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { bearer, buildApp, createCompanyWithIpos, createUser } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

// A minimal valid 1x1 PNG as base64
const VALID_BASE64_PNG =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

describe('Company Onboarding Workflow (FR-ONB-01..03, FR-DOC-01..05)', () => {
  it('allows company_rep to save draft, upload docs, submit, request info, resubmit, and approve', async () => {
    const rep = await createUser(ctx, 'company_rep');
    const admin = await createUser(ctx, 'admin');

    // 1. Initial status: nothing yet
    const initRes = await request(ctx.app).get('/onboarding/company').set(bearer(rep.token));
    expect(initRes.status).toBe(200);
    expect(initRes.body.data).toBeNull();

    // 2. Save Draft
    const draftPayload = {
      legal_name: 'Abyssinia Cloud Tech PLC',
      trade_name: 'Abyssinia Cloud',
      registration_number: `REG-${Date.now()}`,
      legal_entity_type: 'plc',
      country_of_incorporation: 'Ethiopia',
      business_address: 'Bole Medhanialem, Addis Ababa',
      business_email: 'contact@abyssiniacloud.et',
      business_phone: '+251 911 223 344',
      tin: '0012345678',
      representative_name: 'Abebe Kebede',
      representative_email: rep.email,
      representative_title: 'Chief Executive Officer',
      authority_declaration: true,
    };

    const draftRes = await request(ctx.app)
      .post('/onboarding/company/draft')
      .set(bearer(rep.token))
      .send(draftPayload);
    expect(draftRes.status).toBe(200);
    expect(draftRes.body.data.onboarding_status).toBe('draft');
    expect(draftRes.body.data.legal_name).toBe(draftPayload.legal_name);

    // 3. Attempt submission before required documents uploaded -> fails 400
    const failSubmitRes = await request(ctx.app)
      .post('/onboarding/company/submit')
      .set(bearer(rep.token))
      .send({});
    expect(failSubmitRes.status).toBe(400);

    // 4. Document upload validation: reject invalid mime type
    const badDocRes = await request(ctx.app)
      .post('/onboarding/company/documents')
      .set(bearer(rep.token))
      .send({
        document_type: 'commercial_registration',
        file_name: 'exploit.exe',
        mime_type: 'application/x-msdownload',
        content: Buffer.from('malicious').toString('base64'),
      });
    expect(badDocRes.status).toBe(400);

    // 5. Upload required documents: commercial_registration & tin_certificate
    const doc1Res = await request(ctx.app)
      .post('/onboarding/company/documents')
      .set(bearer(rep.token))
      .send({
        document_type: 'commercial_registration',
        file_name: 'commercial_reg.png',
        mime_type: 'image/png',
        content: VALID_BASE64_PNG,
      });
    expect(doc1Res.status).toBe(201);
    expect(doc1Res.body.data.review_status).toBe('pending');
    const doc1Id = doc1Res.body.data.id;

    const doc2Res = await request(ctx.app)
      .post('/onboarding/company/documents')
      .set(bearer(rep.token))
      .send({
        document_type: 'tin_certificate',
        file_name: 'tin_certificate.png',
        mime_type: 'image/png',
        content: VALID_BASE64_PNG,
      });
    expect(doc2Res.status).toBe(201);
    const doc2Id = doc2Res.body.data.id;

    // 6. Access control: document download by owner succeeds, by another user fails (403)
    const otherRep = await createUser(ctx, 'company_rep');
    const unauthorizedDocRes = await request(ctx.app)
      .get(`/onboarding/documents/${doc1Id}`)
      .set(bearer(otherRep.token));
    expect(unauthorizedDocRes.status).toBe(403);

    const ownerDocRes = await request(ctx.app)
      .get(`/onboarding/documents/${doc1Id}`)
      .set(bearer(rep.token));
    expect(ownerDocRes.status).toBe(200);
    expect(ownerDocRes.header['content-type']).toBe('image/png');

    // 7. Submit Application
    const submitRes = await request(ctx.app)
      .post('/onboarding/company/submit')
      .set(bearer(rep.token))
      .send({});
    expect(submitRes.status).toBe(200);
    expect(submitRes.body.data.onboarding_status).toBe('submitted');
    const companyId = submitRes.body.data.id;

    // Verify applicant verification_status is now pending
    const repUserRes = await request(ctx.app).get('/users/me').set(bearer(rep.token));
    expect(repUserRes.body.data.verification_status).toBe('pending');

    // 8. Cannot edit draft or upload docs while submitted
    const lockedEditRes = await request(ctx.app)
      .post('/onboarding/company/draft')
      .set(bearer(rep.token))
      .send({ ...draftPayload, trade_name: 'Illegal Edit' });
    expect(lockedEditRes.status).toBe(409);

    // 9. Admin lists companies and finds this submission
    const adminListRes = await request(ctx.app)
      .get('/admin/companies?status=submitted')
      .set(bearer(admin.token));
    expect(adminListRes.status).toBe(200);
    const listed = adminListRes.body.data.find((c: { id: string }) => c.id === companyId);
    expect(listed).toBeDefined();
    expect(listed.documents_count).toBe(2);

    // 10. Admin views company details
    const adminDetailRes = await request(ctx.app)
      .get(`/admin/companies/${companyId}`)
      .set(bearer(admin.token));
    expect(adminDetailRes.status).toBe(200);
    expect(adminDetailRes.body.data.documents.length).toBe(2);
    expect(adminDetailRes.body.data.status_history.length).toBeGreaterThanOrEqual(1);

    // 11. Admin requests additional information
    const reqInfoRes = await request(ctx.app)
      .post(`/admin/companies/${companyId}/request-info`)
      .set(bearer(admin.token))
      .send({ notes: 'Please provide updated proof of business address' });
    expect(reqInfoRes.status).toBe(200);
    expect(reqInfoRes.body.data.onboarding_status).toBe('additional_info_required');

    // Applicant sees additional_info_request
    const repCheckRes = await request(ctx.app).get('/onboarding/company').set(bearer(rep.token));
    expect(repCheckRes.body.data.onboarding_status).toBe('additional_info_required');
    expect(repCheckRes.body.data.additional_info_request).toBe(
      'Please provide updated proof of business address',
    );

    // 12. Applicant corrects draft and resubmits
    const updateRes = await request(ctx.app)
      .post('/onboarding/company/draft')
      .set(bearer(rep.token))
      .send({ ...draftPayload, business_address: 'Bole Medhanialem Tower 4, Addis Ababa' });
    expect(updateRes.status).toBe(200);

    const resubmitRes = await request(ctx.app)
      .post('/onboarding/company/submit')
      .set(bearer(rep.token))
      .send({});
    expect(resubmitRes.status).toBe(200);
    expect(resubmitRes.body.data.onboarding_status).toBe('resubmitted');

    // 13. Admin reviews supporting document status
    const docReviewRes = await request(ctx.app)
      .patch(`/admin/documents/${doc1Id}/review`)
      .set(bearer(admin.token))
      .send({ status: 'approved', notes: 'Registration verified with Ministry of Trade' });
    expect(docReviewRes.status).toBe(200);
    expect(docReviewRes.body.data.review_status).toBe('approved');

    // 14. Admin approves company application
    const approveRes = await request(ctx.app)
      .post(`/admin/companies/${companyId}/approve`)
      .set(bearer(admin.token))
      .send({ notes: 'Company fully compliant with Dirsha onboarding standards' });
    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.onboarding_status).toBe('approved');

    // 15. Applicant user status is now verified
    const repFinalRes = await request(ctx.app).get('/users/me').set(bearer(rep.token));
    expect(repFinalRes.body.data.verification_status).toBe('verified');
  });

  it('handles company application rejection with mandatory reason', async () => {
    const rep = await createUser(ctx, 'company_rep');
    const admin = await createUser(ctx, 'admin');

    await request(ctx.app)
      .post('/onboarding/company/draft')
      .set(bearer(rep.token))
      .send({
        legal_name: 'Suspicious Corp Ltd',
        registration_number: `REG-REJ-${Date.now()}`,
        tin: '9999999999',
        business_address: 'Unknown',
        business_email: 'scam@suspicious.test',
        business_phone: '+251 900 000 000',
        representative_name: 'Mystery Person',
        representative_email: rep.email,
        authority_declaration: true,
      });

    await request(ctx.app)
      .post('/onboarding/company/documents')
      .set(bearer(rep.token))
      .send({
        document_type: 'commercial_registration',
        file_name: 'doc1.png',
        mime_type: 'image/png',
        content: VALID_BASE64_PNG,
      });

    await request(ctx.app)
      .post('/onboarding/company/documents')
      .set(bearer(rep.token))
      .send({
        document_type: 'tin_certificate',
        file_name: 'doc2.png',
        mime_type: 'image/png',
        content: VALID_BASE64_PNG,
      });

    const submitRes = await request(ctx.app)
      .post('/onboarding/company/submit')
      .set(bearer(rep.token))
      .send({});
    const companyId = submitRes.body.data.id;

    // Admin rejects without reason -> 400
    const failRej = await request(ctx.app)
      .post(`/admin/companies/${companyId}/reject`)
      .set(bearer(admin.token))
      .send({});
    expect(failRej.status).toBe(400);

    // Admin rejects with valid reason
    const rejRes = await request(ctx.app)
      .post(`/admin/companies/${companyId}/reject`)
      .set(bearer(admin.token))
      .send({ reason: 'Fraudulent registration certificate submitted.' });
    expect(rejRes.status).toBe(200);
    expect(rejRes.body.data.onboarding_status).toBe('rejected');
    expect(rejRes.body.data.rejection_reason).toBe('Fraudulent registration certificate submitted.');

    // Applicant verification_status is now rejected
    const repUserRes = await request(ctx.app).get('/users/me').set(bearer(rep.token));
    expect(repUserRes.body.data.verification_status).toBe('rejected');
  });

  it('enforces role authorization: investors cannot access company onboarding endpoints', async () => {
    const investor = await createUser(ctx, 'investor');
    const res = await request(ctx.app)
      .post('/onboarding/company/draft')
      .set(bearer(investor.token))
      .send({
        legal_name: 'Sneaky Investor LLC',
        registration_number: '12345',
      });
    expect(res.status).toBe(403);
  });
});

describe('Broker Onboarding Workflow (FR-ONB-04..05, FR-DOC-01..05)', () => {
  it('allows broker to save draft, upload license, validate expiry, submit, and admin approval', async () => {
    const brokerUser = await createUser(ctx, 'broker');
    const admin = await createUser(ctx, 'admin');

    const brokerDraftPayload = {
      broker_type: 'firm' as const,
      legal_name: 'Lion Capital Securities SC',
      trade_name: 'Lion Securities',
      registration_number: `BRK-REG-${Date.now()}`,
      tin: '0098765432',
      business_address: 'Churchill Road, Addis Ababa',
      city: 'Addis Ababa',
      country: 'Ethiopia',
      business_email: 'info@lionsecurities.et',
      business_phone: '+251 115 500 600',
      license_number: `ECMA-LIC-${Date.now()}`,
      license_category: 'securities_broker',
      licensing_authority: 'Ethiopian Capital Market Authority (ECMA)',
      license_expiry_date: '2028-12-31', // valid future date
      representative_name: 'Dawit Mengistu',
      representative_email: brokerUser.email,
      representative_title: 'Managing Director',
      authority_declaration: true,
    };

    // 1. Save Draft
    const draftRes = await request(ctx.app)
      .post('/onboarding/broker/draft')
      .set(bearer(brokerUser.token))
      .send(brokerDraftPayload);
    expect(draftRes.status).toBe(200);
    expect(draftRes.body.data.onboarding_status).toBe('draft');
    const brokerId = draftRes.body.data.id;

    // 2. Reject expired license
    const expiredDraft = await request(ctx.app)
      .post('/onboarding/broker/draft')
      .set(bearer(brokerUser.token))
      .send({
        ...brokerDraftPayload,
        license_expiry_date: '2020-01-01', // expired
      });
    expect(expiredDraft.status).toBe(200);

    // Attempt submission with expired license -> fails 400
    const failExpiredSubmit = await request(ctx.app)
      .post('/onboarding/broker/submit')
      .set(bearer(brokerUser.token))
      .send({});
    expect(failExpiredSubmit.status).toBe(400);

    // Fix license expiry
    await request(ctx.app)
      .post('/onboarding/broker/draft')
      .set(bearer(brokerUser.token))
      .send({
        ...brokerDraftPayload,
        license_expiry_date: '2028-12-31',
      });

    // 3. Upload mandatory broker_license document
    const docRes = await request(ctx.app)
      .post('/onboarding/broker/documents')
      .set(bearer(brokerUser.token))
      .send({
        document_type: 'broker_license',
        file_name: 'ecma_broker_license.png',
        mime_type: 'image/png',
        content: VALID_BASE64_PNG,
      });
    expect(docRes.status).toBe(201);
    const docId = docRes.body.data.id;

    // 4. Submit application
    const submitRes = await request(ctx.app)
      .post('/onboarding/broker/submit')
      .set(bearer(brokerUser.token))
      .send({});
    expect(submitRes.status).toBe(200);
    expect(submitRes.body.data.onboarding_status).toBe('submitted');

    // 5. Admin lists brokers and inspects details
    const listRes = await request(ctx.app)
      .get('/admin/brokers?status=submitted')
      .set(bearer(admin.token));
    expect(listRes.status).toBe(200);
    const found = listRes.body.data.find((b: { id: string }) => b.id === brokerId);
    expect(found).toBeDefined();

    const detailRes = await request(ctx.app)
      .get(`/admin/brokers/${brokerId}`)
      .set(bearer(admin.token));
    expect(detailRes.status).toBe(200);
    expect(detailRes.body.data.documents.length).toBe(1);

    // 6. Admin approves broker
    const approveRes = await request(ctx.app)
      .post(`/admin/brokers/${brokerId}/approve`)
      .set(bearer(admin.token))
      .send({ notes: 'ECMA broker license verified via registry' });
    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.onboarding_status).toBe('approved');

    // 7. Broker verification_status is now verified
    const userRes = await request(ctx.app).get('/users/me').set(bearer(brokerUser.token));
    expect(userRes.body.data.verification_status).toBe('verified');
  });

  it('non-admin cannot approve broker or company applications', async () => {
    const brokerUser = await createUser(ctx, 'broker');
    const investor = await createUser(ctx, 'investor');

    const draftRes = await request(ctx.app)
      .post('/onboarding/broker/draft')
      .set(bearer(brokerUser.token))
      .send({
        legal_name: 'Self-Approving Broker',
        license_number: `LIC-${Date.now()}`,
        license_category: 'dealer',
        license_expiry_date: '2029-01-01',
        business_address: 'Bole Road, Addis Ababa',
        business_email: 'broker@self.test',
        business_phone: '+251 911 000 000',
      });
    expect(draftRes.status).toBe(200);
    const brokerId = draftRes.body.data.id;

    // Broker attempts to call admin approve endpoint
    const brokerSelfApprove = await request(ctx.app)
      .post(`/admin/brokers/${brokerId}/approve`)
      .set(bearer(brokerUser.token))
      .send({});
    expect(brokerSelfApprove.status).toBe(403);

    // Investor attempts to call admin approve endpoint
    const investorApprove = await request(ctx.app)
      .post(`/admin/brokers/${brokerId}/approve`)
      .set(bearer(investor.token))
      .send({});
    expect(investorApprove.status).toBe(403);
  });
});

describe('Regression: Investor Functionality & Primary Market', () => {
  it('investors can still register, check wallet, and browse open offerings', async () => {
    const investor = await createUser(ctx, 'investor');
    const rep = await createUser(ctx, 'company_rep');

    // Check investor wallet
    const walletRes = await request(ctx.app).get('/wallets/me').set(bearer(investor.token));
    expect(walletRes.status).toBe(200);
    expect(walletRes.body.data.currency).toBe('ETB');
    expect(walletRes.body.data.available_minor).toBe(0);

    // Create an open IPO and browse
    const { ipos } = await createCompanyWithIpos(ctx.db, rep.id, ['open']);
    const iposRes = await request(ctx.app).get('/ipos').set(bearer(investor.token));
    expect(iposRes.status).toBe(200);
    expect(iposRes.body.data.some((item: { id: string }) => item.id === ipos.open)).toBe(true);
  });
});

