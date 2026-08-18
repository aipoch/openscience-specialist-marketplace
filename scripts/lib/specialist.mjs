function assertObject(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("specialist.json must be an object");
  }
}

function assertFields(value, required, optional = []) {
  const allowed = new Set([...required, ...optional]);
  for (const field of Object.keys(value)) {
    if (!allowed.has(field)) {
      throw new Error(`specialist.json contains unknown field: ${field}`);
    }
  }
  for (const field of required) {
    if (!(field in value)) {
      throw new Error(`specialist.json is missing field: ${field}`);
    }
  }
}

function assertString(value, field) {
  if (typeof value !== "string" || !value.trim()) {
    throw new Error(`specialist.json ${field} must be a non-empty string`);
  }
}

function validateSpecialist(specialist, fields) {
  for (const field of ["name", "description", "systemPrompt"]) {
    assertString(specialist[field], fields[field]);
  }
  if (specialist.displayName !== undefined) {
    assertString(specialist.displayName, fields.displayName);
  }
  if (!Array.isArray(specialist.skillIds)) {
    throw new Error(`specialist.json ${fields.skillIds} must be an array`);
  }
  if (!Array.isArray(specialist.connectorIds)) {
    throw new Error(`specialist.json ${fields.connectorIds} must be an array`);
  }
  if (new Set(specialist.skillIds).size !== specialist.skillIds.length) {
    throw new Error(`duplicate specialist.json ${fields.skillIds} entry`);
  }
  if (
    new Set(specialist.connectorIds).size !== specialist.connectorIds.length
  ) {
    throw new Error(`duplicate specialist.json ${fields.connectorIds} entry`);
  }
  return specialist;
}

export function parseSpecialistJson(value) {
  assertObject(value);
  assertFields(
    value,
    ["name", "description", "system_prompt", "skill_ids", "connector_ids"],
    ["display_name"],
  );
  return validateSpecialist(
    {
      name: value.name,
      displayName: value.display_name,
      description: value.description,
      systemPrompt: value.system_prompt,
      skillIds: value.skill_ids,
      connectorIds: value.connector_ids,
    },
    {
      name: "name",
      displayName: "display_name",
      description: "description",
      systemPrompt: "system_prompt",
      skillIds: "skill_ids",
      connectorIds: "connector_ids",
    },
  );
}
