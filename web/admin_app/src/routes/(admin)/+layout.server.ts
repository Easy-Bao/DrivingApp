import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = ({ url }) => ({
  activePath: url.pathname,
});
