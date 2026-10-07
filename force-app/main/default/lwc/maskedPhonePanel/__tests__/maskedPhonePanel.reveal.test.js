import { createElement } from 'lwc';
import MaskedPhonePanel from 'c/maskedPhonePanel';
import getMaskedNumbers from '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers';
import getReasons from '@salesforce/apex/PhoneRevealService.getReasons';
import revealNumber from '@salesforce/apex/PhoneRevealService.revealNumber';

jest.mock('@salesforce/customPermission/Reveal_Phone_Number', () => ({ default: true }), { virtual: true });

jest.mock(
    '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/PhoneRevealService.getReasons',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/PhoneRevealService.revealNumber', () => ({ default: jest.fn() }), { virtual: true });

const ROWS = [
    { label: 'Primary', fieldKey: 'Lead.Phone__c', maskedNumber: '98XXXXXX21', hasNumber: true, canDial: true, sortOrder: 1 },
    { label: 'Secondary', fieldKey: 'Lead.Secondary_Phone__c', maskedNumber: null, hasNumber: false, canDial: false, sortOrder: 2 }
];
const REASONS = [
    'Site visit coordination',
    'Booking / documentation follow-up',
    'Customer escalation / complaint',
    'Dialer down, manual call needed',
    'Number verification / correction',
    'Management review',
    'Other'
];

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function createPanel() {
    const element = createElement('c-masked-phone-panel', { is: MaskedPhonePanel });
    Object.assign(element, { recordId: '00Q000000000001AAA', objectApiName: 'Lead' });
    document.body.appendChild(element);
    getMaskedNumbers.emit(ROWS);
    getReasons.emit(REASONS);
    return element;
}

async function openDialogAndChoose(element, reason, comment) {
    element.shadowRoot.querySelector('[data-id="reveal"]').click();
    await flush();
    const combo = element.shadowRoot.querySelector('[data-id="reason"]');
    combo.dispatchEvent(new CustomEvent('change', { detail: { value: reason } }));
    if (comment !== undefined) {
        const area = element.shadowRoot.querySelector('[data-id="comment"]');
        area.dispatchEvent(new CustomEvent('change', { detail: { value: comment } }));
    }
    await flush();
}

describe('c-masked-phone-panel reveal', () => {
    beforeEach(() => {
        jest.useFakeTimers({ doNotFake: ['setTimeout'] });
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.useRealTimers();
    });

    it('shows a Reveal button only for numbers that exist', async () => {
        const element = createPanel();
        await flush();
        expect(element.shadowRoot.querySelectorAll('[data-id="reveal"]').length).toBe(1);
    });

    it('lists the 7 reasons in the dialog', async () => {
        const element = createPanel();
        await flush();
        element.shadowRoot.querySelector('[data-id="reveal"]').click();
        await flush();
        const combo = element.shadowRoot.querySelector('[data-id="reason"]');
        expect(combo.options.length).toBe(7);
        expect(combo.options[6].value).toBe('Other');
    });

    it('requires a comment for Other', async () => {
        const element = createPanel();
        await flush();
        await openDialogAndChoose(element, 'Other', '');
        expect(element.shadowRoot.querySelector('[data-id="confirm"]').disabled).toBe(true);
    });

    it('reveals the number with the chosen reason and hides it after the time', async () => {
        jest.useFakeTimers();
        revealNumber.mockResolvedValue({ phoneNumber: '9876543221', seconds: 30 });
        const element = createPanel();
        await Promise.resolve();
        element.shadowRoot.querySelector('[data-id="reveal"]').click();
        await Promise.resolve();
        element.shadowRoot.querySelector('[data-id="reason"]').dispatchEvent(
            new CustomEvent('change', { detail: { value: 'Management review' } })
        );
        await Promise.resolve();
        element.shadowRoot.querySelector('[data-id="confirm"]').click();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(revealNumber).toHaveBeenCalledWith({
            recordId: '00Q000000000001AAA',
            fieldKey: 'Lead.Phone__c',
            reason: 'Management review',
            comment: ''
        });
        expect(element.shadowRoot.querySelector('[data-id="revealed"]').textContent).toContain('9876543221');
        expect(element.shadowRoot.querySelector('[data-id="reveal-dialog"]')).toBeNull();

        jest.advanceTimersByTime(30000);
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('[data-id="revealed"]')).toBeNull();
        expect(element.shadowRoot.innerHTML).not.toContain('9876543221');
    });

    it('shows the server message when the reveal is refused', async () => {
        revealNumber.mockRejectedValue({ body: { message: 'You do not have permission to reveal phone numbers.' } });
        const element = createPanel();
        await flush();
        await openDialogAndChoose(element, 'Management review');
        element.shadowRoot.querySelector('[data-id="confirm"]').click();
        await flush();
        expect(element.shadowRoot.querySelector('[data-id="reveal-error"]').textContent).toBe(
            'You do not have permission to reveal phone numbers.'
        );
    });

    it('closes the dialog on Cancel without calling the server', async () => {
        const element = createPanel();
        await flush();
        await openDialogAndChoose(element, 'Management review');
        element.shadowRoot.querySelector('[data-id="cancel"]').click();
        await flush();
        expect(element.shadowRoot.querySelector('[data-id="reveal-dialog"]')).toBeNull();
        expect(revealNumber).not.toHaveBeenCalled();
    });
});
