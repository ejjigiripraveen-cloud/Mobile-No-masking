import { LightningElement ,track ,api} from 'lwc';

export default class SearchComponent extends LightningElement {

     handleChange(event){
        /* eslint-disable no-console */
        //console.log('Search Event Started ');
        const searchKey = event.target.value;
        /* eslint-disable no-console */
        event.preventDefault();
        const searchEvent = new CustomEvent(
            'change', 
            { 
                detail : searchKey
            }
        );
        this.dispatchEvent(searchEvent);
    }

    handleClick(event){
        /* eslint-disable no-console */
        //console.log('Search Event Started ');
        const searchKey = 'all';
        /* eslint-disable no-console */
        event.preventDefault();
        const searchEvent = new CustomEvent(
            'click', 
            { 
                detail : searchKey
            }
        );
        this.dispatchEvent(searchEvent);
    }
}