package com.ny83427.zorro.handlers;

import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class DetermineDriverTest {

	@Test
	public void testHandle() {
		DetermineDriver dd = new DetermineDriver();
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_DRIVER);
		System.out.println("return code: " + dd.handle(ctx));
	}

}
