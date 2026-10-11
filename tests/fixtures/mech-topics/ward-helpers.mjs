export const uniq = (value, index, self) => self.indexOf(value) === index
export const delay = time => new Promise(res => setTimeout(res, time))
export const asSlug = title =>
  title
    .replace(/\s/g, '-')
    .replace(/[^A-Za-z0-9-]/g, '')
    .toLowerCase()
