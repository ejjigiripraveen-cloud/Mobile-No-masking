import { createElement } from 'lwc';
import FindByNumber from 'c/findByNumber';
import findLeads from '@salesforce/apex/FindByNumberController.findLeads';
import { getNavigateCalledWith } from 'lightning/navigation';

jest.mock('@salesforce/apex/FindByNumberController.findLeads', () => ({ default: jest.fn() }), { virtual: true });

const REAL_NUMBER = '9876543221';
const LEAD_ID = '00Q000000000001AAA';

const FOUND = {
    maskedNumber: '98XXXXXX21',
    hasMore: false,
    errorMessage: null,
    leads: [
        {
            recordId: LEAD_ID,
            name: 'Test Lead',
            leadNumber: 'L-0001',
            status: 'New',
            project: 'Project A',
            ownerName: 'Rep One',
            recordTypeName: 'Pre Sales',
            createdDate: '2026-10-01T10:00:00.000Z',
            matchedOn: 'Primary Phone',
            maskedNumber: '98XXXXXX21'
        }
    ]
};

function createComponent() {
    const element = createElement('c-find-by-number', { is: FindByNumber });
    document.body.appendChild(element);
    return element;
}

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function search(element, number) {
    const input = element.shadowRoot.querySelector('[data-id="number"]');
    input.value = number;
    input.dispatchEvent(new CustomEvent('change'));
    await flush();
    element.shadowRoot.querySelector('[data-id="search"]').click();
    await flush();
}

describe('c-find-by-number', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('disables Search until a number is typed', () => {
        const element = createComponent();
        expect(element.shadowRoot.querySelector('[data-id="search"]').disabled).toBe(true);
    });

    it('shows the leads found with masked numbers only', async () => {
        findLeads.mockResolvedValue(FOUND);
        const element = createComponent();

        await search(element, REAL_NUMBER);

        expect(findLeads).toHaveBeenCalledWith({ phoneNumber: REAL_NUMBER });
        const results = element.shadowRoot.querySelectorAll('[data-id="result"]');
        expect(results.length).toBe(1);
        expect(results[0].textContent).toContain('98XXXXXX21');
        expect(results[0].textContent).not.toContain(REAL_NUMBER);
        expect(element.shadowRoot.querySelector('[data-id="summary"]').textContent).toBe('1 lead for 98XXXXXX21');
    });

    it('says when no lead has the number', async () => {
        findLeads.mockResolvedValue({ maskedNumber: '98XXXXXX21', hasMore: false, errorMessage: null, leads: [] });
        const element = createComponent();

        await search(element, REAL_NUMBER);

        expect(element.shadowRoot.querySelector('[data-id="not-found"]').textContent).toContain('98XXXXXX21');
        expect(element.shadowRoot.querySelector('[data-id="result"]')).toBeNull();
    });

    it('shows the server message for a partial number', async () => {
        findLeads.mockResolvedValue({ maskedNumber: '98X21', hasMore: false, errorMessage: 'Enter the full mobile number.', leads: [] });
        const element = createComponent();

        await search(element, '98721');

        expect(element.shadowRoot.querySelector('[data-id="error"]').textContent).toBe('Enter the full mobile number.');
        expect(element.shadowRoot.querySelector('[data-id="not-found"]')).toBeNull();
    });

    it('shows an error when the call fails', async () => {
        findLeads.mockRejectedValue({ body: { message: 'Server error' } });
        const element = createComponent();

        await search(element, REAL_NUMBER);

        expect(element.shadowRoot.querySelector('[data-id="error"]').textContent).toBe('Server error');
    });

    it('opens the lead record', async () => {
        findLeads.mockResolvedValue(FOUND);
        const element = createComponent();
        await search(element, REAL_NUMBER);

        element.shadowRoot.querySelector(`a[data-id="${LEAD_ID}"]`).click();

        const { pageReference } = getNavigateCalledWith();
        expect(pageReference.type).toBe('standard__recordPage');
        expect(pageReference.attributes.recordId).toBe(LEAD_ID);
        expect(pageReference.attributes.actionName).toBe('view');
    });

    it('clears the number and results', async () => {
        findLeads.mockResolvedValue(FOUND);
        const element = createComponent();
        await search(element, REAL_NUMBER);

        element.shadowRoot.querySelector('[data-id="clear"]').click();
        await flush();

        expect(element.shadowRoot.querySelector('[data-id="result"]')).toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="number"]').value).toBe('');
    });
});
