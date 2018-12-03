package com.ny83427.zorro.web;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.jsoup.nodes.Document;

import java.util.Map;

/**
 * Response data of a http request: html document, cookies and some data to be used further
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ResponseData {
    ResponseData(Document document, Map<String, String> cookies) {
        super();
        this.document = document;
        this.cookies = cookies;
    }

    private Document document;

    private Map<String, String> cookies;

    private Map<String, String> data;
}
