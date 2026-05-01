export const getPagination = (query) => {
  const rawLimit = `${query.limit || 20}`.toLowerCase();
  const limit = rawLimit === "all"
    ? null
    : Math.min(Math.max(Number(rawLimit), 1), 100);
  const page = Math.max(Number(query.page || 1), 1);
  const offset = limit === null ? 0 : (page - 1) * limit;
  return { limit, page, offset };
};
