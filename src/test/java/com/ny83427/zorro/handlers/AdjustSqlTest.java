package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import junit.framework.Assert;

import org.apache.commons.io.FileUtils;
import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class AdjustSqlTest {

	@Test
	public void testHandle() throws IOException {
		String basePath = new File(AdjustSqlTest.class.getResource("/").getFile()).getAbsolutePath();
		AdjustSql as = new AdjustSql();
		// "AMU", "02", "03", "AMU345678", "D" cannot change or test case will fail
		ContextInfo ctx = new ContextInfo(Constants.SCENARIO_SQL, "AMU", "02", "03", "AMU345678", "D", basePath, Constants.DEFAULT_DATABASE_TYPE);
		as.handle(ctx);
		
		for(String s : AdjustSql.SQL_FILES) {
			File sql = new File(basePath + "\\NWInst\\me_sql\\" + s + "_AMU.sql");
			File exp = new File(basePath + "\\NWInst\\me_sql\\" + s + "2.sql");
			Assert.assertEquals(FileUtils.readFileToString(sql), FileUtils.readFileToString(exp));
		}
	}

}
