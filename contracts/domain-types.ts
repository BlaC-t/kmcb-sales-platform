/**
 * Design-only shared contracts. The implementation should generate API types
 * from OpenAPI and keep domain types framework-independent.
 */

export type UUID = string;
export type SupportedLocale = 'zh-CN' | 'en' | 'ru' | 'uk';
export type ContentTranslationStatus = 'MISSING' | 'DRAFT' | 'STALE' | 'IN_REVIEW' | 'APPROVED';

export interface ContentPage {
  id: UUID;
  collectionId: UUID;
  pageCode: string;
  routePath: string;
  sectionType: 'COMPANY' | 'UZBEKISTAN_SUBSIDIARY' | 'PRODUCTION_CAPABILITY' | 'PRODUCT_FUNCTION' | 'AUTHORIZED_CASE' | 'OTHER';
  sortOrder: number;
  customerSafe: boolean;
  active: boolean;
  currentRevisionId?: UUID;
  localeStatuses: Partial<Record<SupportedLocale, ContentTranslationStatus>>;
}

export interface ContentBlock {
  id: UUID;
  blockKey: string;
  blockType: 'HERO' | 'TEXT' | 'IMAGE' | 'VIDEO' | 'METRIC' | 'GALLERY' | 'DOCUMENT' | 'CASE_CARD';
  sortOrder: number;
  layout: Record<string, unknown>;
  shared: Record<string, unknown>;
}

export interface ContentRevision {
  id: UUID;
  pageId: UUID;
  versionNo: number;
  sourceLocale: SupportedLocale;
  status: 'DRAFT' | 'IN_REVIEW' | 'APPROVED' | 'PUBLISHED' | 'SUPERSEDED';
  structureChecksum?: string;
  blocks: ContentBlock[];
  rowVersion: number;
}

export interface ContentTranslation {
  id: UUID;
  revisionId: UUID;
  locale: SupportedLocale;
  status: ContentTranslationStatus;
  pageTitle: string;
  pageSummary?: string;
  translationMethod: 'SOURCE' | 'HUMAN' | 'LLM_DRAFT' | 'IMPORT';
  sourceContentChecksum?: string;
  translationChecksum?: string;
  rowVersion: number;
}

export interface MediaAsset {
  id: UUID;
  assetCode: string;
  mediaType: 'IMAGE' | 'VIDEO' | 'DOCUMENT';
  originalFileName: string;
  originalStorageUri: string;
  mimeType: string;
  checksum: string;
  sizeBytes: number;
  rightsStatus: 'INTERNAL' | 'LICENSED' | 'CUSTOMER_AUTHORIZED' | 'RESTRICTED' | 'EXPIRED';
  active: boolean;
  variants: Array<{
    variantCode: string;
    format: string;
    storageUri: string;
    checksum: string;
    widthPx?: number;
    heightPx?: number;
    processingStatus: 'PENDING' | 'READY' | 'FAILED';
  }>;
}

export interface SalesContentRelease {
  id: UUID;
  releaseNumber: string;
  collectionId: UUID;
  channel: string;
  status: 'DRAFT' | 'SCHEDULED' | 'PUBLISHED' | 'SUPERSEDED' | 'ROLLED_BACK' | 'FAILED';
  locales: SupportedLocale[];
  manifest: Record<string, unknown>;
  manifestChecksum: string;
  publishedAt?: string;
}

export interface Project {
  id: UUID;
  projectCode: string;
  projectName: string;
  customerDisplayName?: string;
  countryCode?: string;
  region?: string;
  siteTimeZone: string;
  status: string;
  createdAt: string;
}

export type VersionStatus =
  | 'DRAFT'
  | 'VALIDATING'
  | 'REVIEW_REQUIRED'
  | 'APPROVED'
  | 'PUBLISHED'
  | 'SUPERSEDED'
  | 'RETIRED';

export type RuleEffect = 'REJECT' | 'REQUIRE' | 'WARN' | 'PREFER';
export type Severity = 'BLOCKER' | 'MAJOR' | 'MINOR' | 'INFO';

export interface Quantity {
  originalValue?: number;
  originalUnit?: string;
  normalizedValue?: number;
  normalizedUnit?: string;
  known: boolean;
  source?: EvidenceRef;
}

export interface EvidenceRef {
  sourceType: 'CUSTOMER' | 'SALES_ESTIMATE' | 'TESTWORK' | 'SITE_SURVEY' | 'DOCUMENT' | 'ENGINEER' | 'OBSERVATION';
  sourceId?: UUID;
  page?: number;
  locator?: Record<string, unknown>;
  reliability?: number;
}

export interface FlowsheetNode {
  id: UUID;
  code: string;
  operationTypeCode: string;
  purposeCode?: string;
  parameters: Record<string, unknown>;
  narrative: string;
  designDryTph?: number;
  designWaterM3h?: number;
  position: { x: number; y: number };
}

export interface FlowsheetEdge {
  id: UUID;
  fromNodeId: UUID;
  toNodeId: UUID;
  fromPort: string;
  toPort: string;
  streamRole: string;
  dryTph?: number;
  waterM3h?: number;
  solidsPct?: number;
  p80Mm?: number;
  topSizeMm?: number;
  recycle: boolean;
  properties: Record<string, unknown>;
}

export interface Flowsheet {
  nodes: FlowsheetNode[];
  edges: FlowsheetEdge[];
}

export interface EquipmentSelection {
  id: UUID;
  nodeId: UUID;
  specVersionId: UUID;
  quantityTotal: number;
  quantityDuty: number;
  quantityStandby: number;
  requiredCapacityTph?: number;
  effectiveCapacityPerUnitTph?: number;
  capacityMarginPct?: number;
  selectionReason: string;
  overrideReason?: string;
}

export interface EquipmentOption {
  id: UUID;
  nodeId: UUID;
  specVersionId: UUID;
  rank: number;
  fitStatus: 'PASS' | 'WARN' | 'ENGINEERING_CONFIRMATION_REQUIRED' | 'REJECT';
  score?: number;
  defaultQuantityTotal?: number;
  defaultQuantityDuty?: number;
  defaultQuantityStandby?: number;
  selectionReason: string;
  warnings: ValidationIssue[];
}

export interface SalesConsultation {
  id: UUID;
  sessionNumber: string;
  projectId: UUID;
  questionnaireVersionId: UUID;
  requirementVersionId?: UUID;
  contentReleaseId?: UUID;
  status:
    | 'DRAFT'
    | 'IN_PROGRESS'
    | 'ANSWERS_COMPLETE'
    | 'RECOMMENDING'
    | 'PROPOSAL_READY'
    | 'SUBMITTED_TO_ENGINEERING'
    | 'CLOSED'
    | 'CANCELLED';
  locale: SupportedLocale;
  timeZone: string;
  completenessScore?: number;
  rowVersion: number;
}

export interface SalesProposalRevision {
  id: UUID;
  proposalId: UUID;
  revisionNo: number;
  status:
    | 'SALES_DRAFT'
    | 'READY_FOR_CUSTOMER'
    | 'SUBMITTED_TO_ENGINEERING'
    | 'ACCEPTED_BY_ENGINEERING'
    | 'SUPERSEDED'
    | 'CANCELLED';
  title: string;
  customerPreferences: Record<string, unknown>;
  flowsheet: Flowsheet;
  equipmentOptions: EquipmentOption[];
  equipmentSelections: EquipmentSelection[];
  validationIssues: ValidationIssue[];
  rowVersion: number;
}

export interface CustomerHandout {
  id: UUID;
  handoutNumber: string;
  proposalRevisionId: UUID;
  type: 'PRELIMINARY';
  status: 'GENERATING' | 'PENDING_REVIEW' | 'APPROVED_FOR_DELIVERY' | 'REJECTED' | 'FAILED' | 'SUPERSEDED';
  locale: SupportedLocale;
  timeZone: string;
  disclaimer: string;
  manifest: Record<string, unknown>;
  files: Array<{
    format: 'PDF' | 'DOCX';
    fileName: string;
    contentType: string;
    downloadUrl?: string;
    checksum: string;
  }>;
}

export interface CustomerHandoutReview {
  id: UUID;
  customerHandoutId: UUID;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED';
  requestedBy: UUID;
  requestedAt: string;
  assignedReviewerId?: UUID;
  reviewerId?: UUID;
  reviewedAt?: string;
  decisionReason?: string;
  reviewedManifestChecksum?: string;
}

export interface LlmRun {
  id: UUID;
  projectId?: UUID;
  purpose: 'DOCUMENT_EXTRACTION' | 'FIELD_MAPPING' | 'TRANSLATION_DRAFT' | 'NARRATIVE_DRAFT' | 'CANDIDATE_SUGGESTION';
  provider: string;
  modelId: string;
  promptTemplateCode: string;
  promptTemplateVersion: string;
  inputChecksum: string;
  status: 'QUEUED' | 'RUNNING' | 'SUCCEEDED' | 'FAILED' | 'BLOCKED_BY_POLICY' | 'CANCELLED';
  inputTokens?: number;
  outputTokens?: number;
  estimatedCost?: number;
  humanDisposition?: 'ACCEPTED' | 'MODIFIED' | 'REJECTED';
  requestedAt: string;
}

export interface ValidationIssue {
  severity: Severity;
  code: string;
  ruleCode?: string;
  entityType?: string;
  entityId?: UUID;
  path?: string;
  message: string;
  evidence?: Record<string, unknown>;
}

export interface RecommendationDependency {
  type: 'INPUT' | 'ALGORITHM' | 'RULE_SET' | 'EQUIPMENT_CATALOG' | 'CASE_LIBRARY' | 'FEATURE_SCHEMA';
  id: string;
  version: string;
  checksum?: string;
}

export interface DomainEvent<T extends Record<string, unknown>> {
  eventId: UUID;
  eventType: string;
  schemaVersion: number;
  occurredAt: string;
  aggregateType: string;
  aggregateId: UUID;
  correlationId?: UUID;
  causationId?: UUID;
  data: T;
}
