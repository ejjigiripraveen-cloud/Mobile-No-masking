<!--
  This is a Lightning Out App component.
  It allows your Lightning component (like slashPhone) to be used outside Salesforce Lightning (e.g., in a Visualforce Page or external site).
-->
<aura:application 
  access="GLOBAL" 
  extends="ltng:outApp" 
  description="The Lightning Out app which hosts the demo adapter.">

  <!--
    This line ensures that the component 'slashPhone' is loaded and available
    to be created dynamically using $Lightning.createComponent().
    'c:' means it's a component from the current namespace.
  -->
  <aura:dependency resource="c:slashPhone"/>

</aura:application>