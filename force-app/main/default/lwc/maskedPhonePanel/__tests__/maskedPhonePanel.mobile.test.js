import { createElement } from 'lwc';
import MaskedPhonePanel from 'c/maskedPhonePanel';
import getMaskedNumbers from '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers';

jest.mock('@salesforce/client/formFactor', () => ({ default: 'Small' }), { virtual: true });

jest.mock(
    '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

describe('c-masked-phone-panel on mobile', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('never renders click-to-dial on mobile, even when enabled', async () => {
        const element = createElement('c-masked-phone-panel', { is: MaskedPhonePanel });
        Object.assign(element, { recordId: '00Q000000000001AAA', objectApiName: 'Lead', enableClickToDial: true });
        document.body.appendChild(element);

        getMaskedNumbers.emit([
            { label: 'Primary', fieldKey: 'Lead.Phone__c', maskedNumber: '98XXXXXX21', hasNumber: true, canDial: true, sortOrder: 1 }
        ]);
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('lightning-click-to-dial')).toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="masked"]').textContent).toBe('98XXXXXX21');
        expect(element.shadowRoot.querySelector('lightning-icon').title).toBe('Calling from the mobile app is not available yet');
    });
});
