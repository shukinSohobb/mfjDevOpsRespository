<aura:application extends="force:slds"  access="GLOBAL">
     <aura:attribute name="recordId" type="String" />
    <c:ShippingSalesReportOutputCmp recordId="{!v.recordId}" />
</aura:application>