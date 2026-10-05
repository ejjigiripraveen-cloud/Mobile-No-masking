import { createElement } from 'lwc';
import MaskedPhonePanel from 'c/maskedPhonePanel';
import getMaskedNumbers from '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

jest.mock(
    '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex',
    () => ({ refreshApex: jest.fn(() => Promise.resolve()) }),
    { virtual: true }
);

const RECORD_ID = '00Q000000000001AAA';
const REAL_PRIMARY = '9876543221';

const ROWS = [
    { label: 'Primary', fieldKey: 'Lead.Phone__c', maskedNumber: '98XXXXXX21', hasNumber: true, canDial: true, sortOrder: 1 },
    { label: 'Secondary', fieldKey: 'Lead.Secondary_Phone__c', maskedNumber: null, hasNumber: false, canDial: false, sortOrder: 2 }
];

function createPanel(props = {}) {
    const element = createElement('c-masked-phone-panel', { is: MaskedPhonePanel });
    Object.assign(element, { recordId: RECORD_ID, objectApiName: 'Lead' }, props);
    document.body.appendChild(element);
    return element;
}

const flush = () => Promise.resolve();

describe('c-masked-phone-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows a spinner until numbers load', () => {
        const element = createPanel();
        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
    });

    it('shows masked numbers and never the real number', async () => {
        const element = createPanel();
        getMaskedNumbers.emit(ROWS);
        await flush();

        const masked = element.shadowRoot.querySelector('[data-id="masked"]');
        expect(masked.textContent).toBe('98XXXXXX21');
        expect(element.shadowRoot.innerHTML).not.toContain(REAL_PRIMARY);
        expect(element.shadowRoot.querySelector('lightning-click-to-dial')).toBeNull();
    });

    it('shows an empty text for a missing number', async () => {
        const element = createPanel();
        getMaskedNumbers.emit(ROWS);
        await flush();

        const empty = element.shadowRoot.querySelector('[data-id="empty"]');
        expect(empty.textContent).toBe('No secondary number');
    });

    it('renders click-to-dial with the masked value and field key when enabled', async () => {
        const element = createPanel({ enableClickToDial: true });
        getMaskedNumbers.emit(ROWS);
        await flush();

        const dial = element.shadowRoot.querySelectorAll('lightning-click-to-dial');
        expect(dial.length).toBe(1);
        expect(dial[0].value).toBe('98XXXXXX21');
        expect(dial[0].recordId).toBe(RECORD_ID);
        expect(dial[0].params).toBe('fieldKey=Lead.Phone__c');
    });

    it('shows the server error message', async () => {
        const element = createPanel();
        getMaskedNumbers.error({ message: 'You do not have access to this record.' });
        await flush();

        const error = element.shadowRoot.querySelector('[data-id="error"]');
        expect(error.textContent).toBe('You do not have access to this record.');
    });

    it('shows a message when no phone fields are configured', async () => {
        const element = createPanel();
        getMaskedNumbers.emit([]);
        await flush();

        expect(element.shadowRoot.querySelector('[data-id="none"]')).not.toBeNull();
    });

    it('reloads the masked numbers when the record is saved', async () => {
        createPanel();
        getMaskedNumbers.emit(ROWS);
        getRecord.emit({ lastModifiedDate: '2026-10-05T10:00:00.000Z' });
        await flush();
        expect(refreshApex).not.toHaveBeenCalled();

        getRecord.emit({ lastModifiedDate: '2026-10-05T10:05:00.000Z' });
        await flush();
        expect(refreshApex).toHaveBeenCalledTimes(1);
    });
});
