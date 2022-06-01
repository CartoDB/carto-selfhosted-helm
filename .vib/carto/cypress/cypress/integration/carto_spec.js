/// <reference types="cypress" />

it('Login page is shown', () => {
  cy.visit('https://carto.vmw/');
  cy.get('img.logo')
    .should('have.attr', 'src')
    .should('include', 'carto-logo-negative.svg');
});
