package com.ny83427.zorro.web;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;

import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import com.ny83427.zorro.utility.MFGUtility;

/**
 * Web utility class to perform http post/get request
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class MFGWebUtils {
    private static final int TIME_OUT = 10;

    /**
     * Logon NWA, get necessary data and cookies for further usage
     *
     * @param baseUrl  base url before logon
     * @param loginUrl logon url address
     * @param password user will always be administrator, thus we only need password to logon
     * @return ResponseData
     * @throws IOException
     */
    public static ResponseData nwaAdminLogin(String baseUrl, String loginUrl, String password) throws IOException {
        // open base url first, get j_salt for login
        ResponseData resp = request(baseUrl, false, null, null, null);

        // logon with administrator: prepare post data, header and submit request
        Map<String, String> data = new HashMap<String, String>();
        data.put("no_cert_storing", "on");
        data.put("j_salt", resp.getDocument().select("input[name=j_salt]").get(0).val());
        data.put("j_username", "administrator");
        data.put("j_password", password);
        data.put("uidPasswordLogon", "Log On");

        Map<String, String> header = new HashMap<String, String>();
        header.put("Referer", baseUrl);

        resp = request(loginUrl, true, header, data, resp.getCookies());

        data = new HashMap<String, String>();
        Document doc = resp.getDocument();
        data.put("sap-wd-appwndid", doc.select("input[name=sap-wd-appwndid]").get(0).val());
        data.put("sap-wd-cltwndid", doc.select("input[name=sap-wd-cltwndid]").get(0).val());
        data.put("sap-wd-secure-id", doc.select("input[name=sap-wd-secure-id]").get(0).val());
        data.put("sap-wd-norefresh", "X");

        resp.setData(data);

        return resp;
    }

    /**
     * Submit a http request and return the response data
     *
     * @param url     url address of http request
     * @param post    method is post or not(get)
     * @param header  http header
     * @param data    data that will be posted
     * @param cookies cookies indicate a valid session user hold
     * @return ResponseData
     * @throws IOException
     */
    public static ResponseData request(String url, boolean post,
                                       Map<String, String> header, Map<String, String> data, Map<String, String> cookies) throws IOException {
        Connection conn = prepareConnection(url);

        if (post) {
            conn.header("Content-Type", "application/x-www-form-urlencoded");
        }

        if (!MFGUtility.isEmpty(header)) {
            for (Entry<String, String> entry : header.entrySet()) {
                conn.header(entry.getKey(), entry.getValue());
            }
        }

        if (!MFGUtility.isEmpty(data)) {
            conn.data(data);
        }

        if (!MFGUtility.isEmpty(cookies)) {
            conn.cookies(cookies);
        }


        Document doc = post ? conn.post() : conn.get();
        return new ResponseData(doc, conn.response().cookies());
    }

    /**
     * Prepare a http connection according to given url
     *
     * @param url URL that will be connected to
     */
    public static Connection prepareConnection(String url) {
        Connection c = Jsoup.connect(url).timeout(TIME_OUT * 1000);
        c.userAgent("Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)");
        c.header("Connection", "keep-alive");
        c.header("Accept", "text/html, application/xhtml+xml, */*");
        c.header("Accept-Encoding", "gzip, deflate");
        c.header("Accept-Language", "en");
        c.header("Connection", "Keep-Alive");

        String host = url.substring(7);
        c.header("Host", host.substring(0, host.indexOf("/")));

        return c;
    }

}
