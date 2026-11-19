import { expect, test } from '@playwright/test';

test('strona pokazuje Minutnik i zestawy PRM z JSON-a', async ({ page }) => {
	await page.goto('');
	await expect(page.getByRole('heading', { name: 'Minutnik' })).toBeVisible();
	await expect(page.getByRole('list', { name: 'Zestawy' }).getByRole('listitem')).toHaveText([/^12 grup12 grup · \d+ min$/, /^8 grup8 grup · \d+ min$/]);
});
