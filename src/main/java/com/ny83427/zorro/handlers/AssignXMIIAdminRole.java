package com.ny83427.zorro.handlers;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import com.ny83427.zorro.utility.MFGUtility;
import com.ny83427.zorro.web.MFGWebUtils;
import com.ny83427.zorro.web.ResponseData;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * <pre>
 * This class will assign SAP_XMII_Administrator, SAP_XMII_Super_Administrator role to NWA administrator
 * so that MEINT can be deployed successfully, formerly it will submit various http requests to finish the task
 * that user will usually open web browser and perform manual operations.
 *
 * However, there is a better solution to use UME API provided by NetWeaver, the code will be like this:
 * <code>
 * try {
 * 	IUserFactory userFactory = UMFactory.getUserFactory();
 * 	IUser admin = userFactory.getUserByLogonID("administrator");
 * 	IUserMaint userMaint = userFactory.getMutableUser(admin.getUniqueID());
 *
 * 	IRoleFactory rFactory = UMFactory.getRoleFactory();
 * 	IRole xmiiAdm = rFactory.getRoleByUniqueName("SAP_XMII_Administrator");
 * 	IRole xmiiSuperAdm = rFactory.getRoleByUniqueName("SAP_XMII_Super_Administrator");
 *
 * 	userMaint.addToRole(xmiiAdm.getUniqueID());
 * 	userMaint.addToRole(xmiiSuperAdm.getUniqueID());
 *
 * 	userMaint.save();
 * 	userMaint.commit();
 * } catch (UMException e) {
 * 	e.printStackTrace();
 * }
 * </code>
 * Simply prepare a SCA that will execute these codes or consume UMFactory in standalone mode will work.
 * Thus we have a new strategy like this:
 * 1. Deploy ASSIGN_XMII_ROLE00_0.sca(demo.sap.com, Web Dynpro, contains code above) with XMII and MII_ADMIN together
 * 2. Run Web Dynpro JAVA Application: start http://%computername%:5%NR1%00/webdynpro/resources/demo.sap.com/xmiirole/AssignRole?SAPtestId=9#
 *
 * However, the original implementation{@link #_handle(ContextInfo)} still work well.
 * </pre>
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class AssignXMIIAdminRole implements Handler {
    private static final String WEB_DYNPRO_URL = "webdynpro/resources/demo.sap.com/xmiirole/AssignRole?SAPtestId=9#";

    public int handle(ContextInfo ctx) {
        int exitCode = Constants.NO_ERROR_CODE;
        String instNo = ctx.getInstNo();
        try {
            Thread.sleep(2000);
            MFGWebUtils.prepareConnection("http://" + System.getenv("COMPUTERNAME") + ":5" + instNo + "00" + "/" + WEB_DYNPRO_URL).get();
        } catch (Exception e) {
            try {
                System.out.println("Host " + System.getenv("COMPUTERNAME") + " does not work, we will try to use localhost.");
                Thread.sleep(2000);
                MFGWebUtils.prepareConnection("http://localhost:5" + instNo + "00/" + WEB_DYNPRO_URL).get();
            } catch (Exception ex) {
                // in case the stable way doesn't work, we will fall back to the old way
                exitCode = this._handle(ctx);
            }
        }

        if (exitCode == Constants.NO_ERROR_CODE) {
            System.out.println("Role 'SAP_XMII_Administrator, SAP_XMII_Super_Administrator' assigned to Administrator successfully, now you have XMII admin right");
        }

        return exitCode;
    }

    private static String HOST = null;
    private static String LOGIN_URL = "/webdynpro/dispatcher/sap.com/tc~sec~ume~wd~umeadmin/j_security_check";
    private static String USER_ADMIN_URL = "/webdynpro/dispatcher/sap.com/tc~sec~ume~wd~umeadmin/UmeAdminApp";
    private static Map<String, String> HEADER = null;
    private static Map<String, String> COOKIES = null;
    private static Map<String, String> DATA = null;

    /**
     * Assign SAP_XMII_Administrator, SAP_XMII_Super_Administrator role to NWA administrator via submit http requests
     *
     * @param ctx Context information
     * @return exit code
     * @see #handle(ContextInfo)
     */
    private int _handle(ContextInfo ctx) {
        int exitCode = Constants.NO_ERROR_CODE;
        String instNo = ctx.getInstNo();
        String password = ctx.getMasterPassword();

        // workaround: sometimes it seems there will be timeout exception using localhost:50000
        HOST = "http://" + System.getenv("COMPUTERNAME") + ":5" + instNo + "00";
        try {
            Thread.sleep(2000);
            MFGWebUtils.prepareConnection(HOST + "/nwa").get();
        } catch (Exception ex) {
            try {
                Thread.sleep(2000);
                MFGWebUtils.prepareConnection("http://localhost:5" + instNo + "00/nwa").get();
                HOST = "http://localhost:5" + instNo + "00";
            } catch (Exception e) {
                e.printStackTrace();
                return Constants.COMMON_ERROR_CODE;
            }
        }

        try {
            LOGIN_URL = HOST + LOGIN_URL;
            USER_ADMIN_URL = HOST + USER_ADMIN_URL;

            assignXMIIAdminRole(password);
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Failed to add XMII Admin Role to administrator, please open browser to operate");
            exitCode = Constants.COMMON_ERROR_CODE;
        } finally {
            try {
                // no matter what happens, we need to logout finally
                if (!MFGUtility.isEmpty(DATA) && !MFGUtility.isEmpty(COOKIES)) {
                    fireEvent("Link_ActivateIdINMJJKNE.AdministrationHeaderView.LogOffLinkToAction1CtrlfalseShiftfalseClientActionsubmiturEventNameLINKCLICKForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNE.AdministrationHeaderView.LogOffLinkToAction1\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");
                    System.out.println("Administrator logout successfully, bye~");
                }
            } catch (IOException e) {
                e.printStackTrace();
            }

        }

        return exitCode;
    }

    /**
     * <pre>
     * Assign XMII admin and super admin role to NWA administrator via submit http requests
     * </pre>
     *
     * @param password password of NWA administrator
     */
    private void assignXMIIAdminRole(String password) throws IOException {
        ResponseData resp = MFGWebUtils.nwaAdminLogin(USER_ADMIN_URL, LOGIN_URL, password);
        Map<String, String> cookies = resp.getCookies();

        DATA = resp.getData();

        HEADER = new HashMap<String, String>();
        HEADER.put("Referer", USER_ADMIN_URL);
        HEADER.put("x-requested-with", "XMLHttpRequest");
        HEADER.put("Accept", "*/*");

        // press 'Go' button to show user list
        DATA.put(Constants.EVENT_KEY, "Button_PressIdINMJJKNE.BasicSearchView.SearchButton1ClientActionsubmiturEventNameBUTTONCLICKForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNE.BasicSearchView.SearchButton1\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");
        ResponseData resp2 = MFGWebUtils.request(USER_ADMIN_URL, true, HEADER, DATA, cookies);
        Map<String, String> cookies2 = resp2.getCookies();

        COOKIES = new HashMap<String, String>();
        COOKIES.put("JSESSIONID", cookies.get("JSESSIONID"));
        COOKIES.put("JSESSIONMARKID", cookies.get("JSESSIONMARKID"));
        COOKIES.put("MYSAPSSO2", cookies.get("MYSAPSSO2"));
        // get saplb_* from cookies2 (sometimes it's not there in cookies )
        COOKIES.put("saplb_*", cookies2.get("saplb_*"));

        // select the 1st line: administrator
        fireEvent("SapTable_RowSelectIdINMJJKNEPINJ.UserSearchResultView.userResultTableRowIndex1RowUserDataResponseTableRows.0CellUserDataAccessTypeSTANDARDTriggerCellIdINMJJKNEPINJ.UserSearchResultView.userResultTable:1.0ClientActionsubmiturEventNameRowSelectForm_RequestId...formAsyncfalseFocusInfo@{\"iRowIndex\": 1, \"iColIndex\": 0, \"sFocussedId\": \"INMJJKNEPINJ.UserSearchResultView.userResultTable\", \"sApplyControlId\": \"INMJJKNEPINJ.UserSearchResultView.userResultTable\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");

        // press button Modify to modify user
        fireEvent("Button_PressIdINMJJKNEPINJ.DisplayUserView.editClientActionsubmiturEventNameBUTTONCLICKForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNEPINJ.DisplayUserView.edit\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");

        // switch to 'Assigned Roles' tab(in ModifUserView or DisplayUserView)
        // if SAP_XMII_Administrator is arelady assigned, simply quit
        String html = fireEvent("TabStrip_TabSelectIdINMJJKNEPINJ.ModifyUserView.TabStripItemIdINMJJKNEPINJ.ModifyUserView.associatedRolesItemIndex4ClientActionsubmiturEventNameTabSelectForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNEPINJ.ModifyUserView.associatedRoles-focus\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle").getDocument().html();
        if (html != null && html.contains("SAP_XMII_Administrator")) {
            System.out.println("Role SAP_XMII_Administrator has been assigned to Administrator already.");

            // click cancel
            fireEvent("Button_PressIdINMJJKNEPINJ.ModifyUserView.cancelClientActionsubmiturEventNameBUTTONCLICKForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNEPINJ.ModifyUserView.cancel\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");
            return;
        }

        // input '*XMII*' and press 'Go' button
        fireEvent("InputField_ChangeIdINMJJKNEPINJAHAG.AssignParentRolesView.inputSearchValue*XMII*DelayfullurEventNameINPUTFIELDCHANGEButton_PressIdINMJJKNEPINJAHAG.AssignParentRolesView.buttonRoleSearchClientActionsubmiturEventNameBUTTONCLICKForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNEPINJAHAG.AssignParentRolesView.buttonRoleSearch\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");

        // select the 1st role 'SAP_XMII_Administrator'
        fireEvent("SapTable_RowSelectIdINMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTableRowIndex1RowUserDataResponseTable.ResponseTableRows.0CellUserDataAccessTypeSTANDARDTriggerCellIdINMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTable:1.0ClientActionsubmiturEventNameRowSelectForm_RequestId...formAsyncfalseFocusInfo@{\"iRowIndex\": 1, \"iColIndex\": 0, \"sFocussedId\": \"INMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTable\", \"sApplyControlId\": \"INMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTable\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");

        // select the 7th role 'SAP_XMII_Super_Administrator'
        fireEvent("SapTable_RowSelectIdINMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTableRowIndex7RowUserDataResponseTable.ResponseTableRows.6CellUserDataAccessTypeTOGGLETriggerCellIdINMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTable:7.6ClientActionsubmiturEventNameRowSelectForm_RequestId...formAsyncfalseFocusInfo@{\"iRowIndex\": 4, \"iColIndex\": 0, \"sFocussedId\": \"INMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTable\", \"sApplyControlId\": \"INMJJKNEPINJAHAG.AssignParentRolesView.availableRolesTable\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");

        // press add button to add role
        fireEvent("Button_PressIdINMJJKNEPINJAHAG.AssignParentRolesView.buttonRoleAddClientActionsubmiturEventNameBUTTONCLICKForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNEPINJAHAG.AssignParentRolesView.buttonRoleAdd\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");

        // press save button to save data
        fireEvent("Button_PressIdINMJJKNEPINJ.ModifyUserView.saveClientActionsubmiturEventNameBUTTONCLICKForm_RequestId...formAsyncfalseFocusInfo@{\"sFocussedId\": \"INMJJKNEPINJ.ModifyUserView.save\"}HashDomChangedfalseIsDirtyfalseEnqueueCardinalitysingle");

        System.out.println("Role 'SAP_XMII_Administrator' assigned to Administrator successfully, now you have XMII admin right");
    }

    /**
     * fire a AJAX event
     *
     * @param event event ID
     * @return response data
     * @throws IOException
     */
    private ResponseData fireEvent(String event) throws IOException {
        DATA.put(Constants.EVENT_KEY, event);
        return MFGWebUtils.request(USER_ADMIN_URL, true, HEADER, DATA, COOKIES);
    }

}
